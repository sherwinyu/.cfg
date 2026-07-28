from flask import Flask, request, abort
import datetime

import sys
import os
import subprocess
import threading
import logging
from logging.handlers import RotatingFileHandler
import time
import json

from consts import PORT
from lib import parse_time_format, setup_logging, restart_application


app = Flask(__name__)
script_dir = os.path.dirname(os.path.realpath(__file__))
log_path = os.path.join(script_dir, 'server.log')
app.logger = setup_logging(log_path)

def log(msg):
    app.logger.info(msg)

def modify_hosts(action, domain):
    log(f'### ### hosts {action} {domain}')
    subprocess.run(["/opt/homebrew/bin/hosts", action, domain])

def reblock_domains(domains, duration_string, orig_ts, unblock_counter):
    log(f'### Reblock {unblock_counter}: {domains} {duration_string} {orig_ts}')
    for domain in domains:
        modify_hosts("enable", domain)

unblock_counter = 0

@app.route('/unblock', methods=['POST'])
def unblock_domain():
    global unblock_counter
    data = request.json

    # Accept a list of domains (so e.g. reddit.com + www.reddit.com unblock
    # together), falling back to a single 'domain' for backward compatibility.
    domains = data.get('domains')
    if not domains:
        single = data.get('domain')
        domains = [single] if single else []
    if not domains:
        abort(400, description="No domain(s) provided")  # 400 Bad Request

    duration_string = data['duration_string']
    parsed = parse_time_format(duration_string)
    if not parsed:
        abort(400, description="Invalid duration format")  # Raise a 400 Bad Request error with a custom message

    duration = convert_to_seconds(parsed)

    orig_ts = datetime.datetime.now().strftime('%H:%M:%S')  # Corrected format '%H:%m:%S' to '%H:%M:%S'

    for domain in domains:
        modify_hosts("disable", domain)
    log(f'### Unblock {unblock_counter}: {domains} {duration_string} {orig_ts}')
    timer = threading.Timer(duration, reblock_domains, args=[domains, duration_string, orig_ts, unblock_counter])
    timer.start()
    unblock_counter += 1
    return f"Unblocked {', '.join(domains)} for {duration_string}"

def convert_to_seconds(time_tuple):
    number, unit = time_tuple
    if unit == 'm':
        return number * 60  # Convert minutes to seconds
    elif unit == 's':
        return number      # Already in seconds
    else:
        raise ValueError("Invalid unit: must be 'm' or 's'")

def check_root():
    if os.geteuid() != 0:
        log("Server must be run as root")
        sys.exit(1)

if __name__ == '__main__':
    check_root()


    log(f' ')
    log(f'################################# ')
    log(f'## Server starting on port {PORT}')
    log(f'################################# ')
    app.run(debug=False, host='127.0.0.1', port=PORT)
