import {
  duoLayer,
  FromKeyParam,
  ifDevice,
  layer,
  map,
  mapSimultaneous,
  Modifier,
  rule,
  simlayer,
  toKey,
  ToKeyParam,
  toNotificationMessage,
  toPaste,
  toRemoveNotificationMessage,
  withCondition,
  withMapper,
  writeToProfile,
} from "karabiner.ts";

// TO RUN: `npm run build`

// ! Change '--dry-run' to your Karabiner-Elements Profile name.
// (--dry-run print the config json into console)
// + Create a new profile if needed.
// type Manipulators = ReturnType<ReturnType<typeof withCondition>>
function appleKeyboardOnly(manipulators: any[]) {
  return withCondition(
    ifDevice(
      [{ is_built_in_keyboard: true }, { vendor_id: 1452 }],
      "Apple Keyboards only",
    ),
  )(manipulators);
}
writeToProfile("karabiner-config-profile", [
  fg_hyper(),
  tab_hyper_rule(),
  capslock_zoot_rule(),
  text_editing_layer(),
  sel_layer(),
  del_layer(),
  nav_layer(),
  ds_nav_layer(),
  easy_mods_rules(),
  symbol_layer(),
  rule("jk => Esc").manipulators(
    appleKeyboardOnly([mapSimultaneous(["k", "j"]).to("escape")]),
  ),
  rule("right command => del").manipulators(
    appleKeyboardOnly([
      map("right_command", { optional: "any" })
        .toIfAlone("delete_or_backspace")
        .toIfHeldDown({ key_code: "right_command" })
        .toDelayedAction(toKey("vk_none"), toKey("vk_none"))
        .parameters({
          // If pressed alone for more than 500ms, treat as modifier
          "basic.to_if_alone_timeout_milliseconds": 500,

          // Allows usage as modifier immediately
          "basic.to_if_held_down_threshold_milliseconds": 0,
        }),
    ]),
  ),
  // rule('left command alone => undo').manipulators(appleKeyboardOnly([
  //   map('left_command')
  //     .toIfAlone('z', 'command')
  //     .toIfHeldDown({ key_code: 'left_command' })
  //     .toDelayedAction(toKey('vk_none'), toKey('vk_none'))
  //     .parameters({
  //       "basic.to_if_alone_timeout_milliseconds": 500,
  //       "basic.to_if_held_down_threshold_milliseconds": 0
  //     })
  // ])),
]);

function sel_layer() {
  return withCondition(
    ifDevice(
      [{ is_built_in_keyboard: true }, { vendor_id: 1452 }],
      "Apple Keyboards only",
    ),
  )([
    duoLayer("e", "f", "selection layer")
      .notification("Selection🧺")
      .threshold(50)
      .manipulators([
        map("a").to("left_arrow", ["command", "shift"]),
        map(";").to("right_arrow", ["command", "shift"]),

        map("h").to("left_arrow", ["option", "shift"]),
        map("j").to("down_arrow", ["option", "shift"]),
        map("k").to("up_arrow", ["option", "shift"]),
        map("l").to("right_arrow", ["option", "shift"]),

        map("u")
          .to("left_arrow", ["option"])
          .to("right_arrow", ["option", "shift"]),

        map("i")
          .to("up_arrow", ["option"])
          .to("down_arrow", ["option", "shift"]),
      ]),
  ])[0];
}
function del_layer() {
  return duoLayer("w", "f", "deletion layer")
    .notification("Deletion 🔪")
    .manipulators(
      appleKeyboardOnly([
        map("a")
          .to("left_arrow", ["command", "shift"])
          .to("delete_or_backspace"),
        map(";")
          .to("right_arrow", ["command", "shift"])
          .to("delete_or_backspace"),

        map("h")
          .to("left_arrow", ["option", "shift"])
          .to("delete_or_backspace"),
        map("j")
          .to("down_arrow", ["option", "shift"])
          .to("delete_or_backspace"),
        map("k").to("up_arrow", ["option", "shift"]).to("delete_or_backspace"),
        map("l")
          .to("right_arrow", ["option", "shift"])
          .to("delete_or_backspace"),

        map("u")
          .to("left_arrow", ["option"])
          .to("right_arrow", ["option", "shift"])
          .to("delete_or_backspace"),

        map("i")
          .to("left_arrow", ["command"])
          .to("right_arrow", ["command", "shift"])
          .to("delete_or_backspace"),
      ]),
    );
}

function text_editing_layer() {
  return simlayer("q", "text_editing")
    .toIfActivated(toNotificationMessage("simlayer-e", "Text Editing mode"))
    .toIfDeactivated(toRemoveNotificationMessage("simlayer-e"))
    .manipulators(
      appleKeyboardOnly([
        map("a").to("a", "command"),
        map("s").to("s", ["control", "command"]),
        map("p")
          .to("left_arrow", "command")
          .to("right_arrow", ["shift", "command"]),
        // map('k').to('up_arrow', 'control'),
        // map('j').to('down_arrow', 'control')
      ]),
    );
}

function nav_layer() {
  return (
    simlayer("d", "nav", 200)
      // .notification('Nav')
      .toIfActivated(toNotificationMessage("simlayer-d", "Navigation 🧭"))
      .toIfDeactivated(toRemoveNotificationMessage("simlayer-d"))
      .manipulators(
        appleKeyboardOnly([
          map("h").to("left_arrow"),
          map("l").to("right_arrow"),
          map("k").to("up_arrow"),
          map("j").to("down_arrow"),

          map("u").to("[", "command"),
          map("i").to("]", "command"),

          map("a").to("left_arrow", "command"),
          map(";").to("right_arrow", "command"),

          map("f").to("left_option"),
          map("s").to("left_shift"),
        ]),
      )
  );
}
function ds_nav_layer() {
  return duoLayer("d", "s", "ds nav")
    .threshold(50)
    .notification("Nav Shift 🧺 🧭")
    .manipulators(
      appleKeyboardOnly([
        map("h").to("left_arrow", "left_shift"),
        map("l").to("right_arrow", "left_shift"),
        map("k").to("up_arrow", "left_shift"),
        map("j").to("down_arrow", "left_shift"),

        map("u").to("[", ["command", "left_shift"]),
        map("i").to("]", ["command", "left_shift"]),

        map("a").to("left_arrow", "command"),
        map(";").to("right_arrow", "command"),

        map("f").to("left_option"),
        map("s").to("left_shift"),
      ]),
    );
}

function easy_mods_rules() {
  return rule("easy mods").manipulators(
    appleKeyboardOnly([
      withMapper<ToKeyParam, ToKeyParam>({
        z: "left_control",
        x: "left_option",
        slash: "right_control",
        s: "left_shift",
        f: "left_option",
      })((lhs, rhs) => {
        return map(lhs as FromKeyParam, "optionalAny")
          .toIfAlone(lhs as ToKeyParam, {}, { halt: true })
          .toIfHeldDown(rhs, {}, { halt: true })
          .toDelayedAction(toKey("vk_none"), toKey(lhs))
          .parameters({
            "basic.to_delayed_action_delay_milliseconds": 500,
            "basic.to_if_held_down_threshold_milliseconds": 120,
          });
      }),
    ]),
  );
}

function symbol_layer() {
  return duoLayer("-", "=", "-= Symbol Layer")
    .threshold(50)
    .notification("Symbols")
    .options({ key_down_order: "strict" })
    .manipulators(
      appleKeyboardOnly([
        {
          2: toPaste("⌫"),
          3: toPaste("⌦"),
          4: toPaste("⇥"),
          5: toPaste("⎋"),
          6: toPaste("⌘"),
          7: toPaste("⌥"),
          8: toPaste("⌃"),
          9: toPaste("⇧"),
          0: toPaste("⇪"),
          ",": toPaste("‹"),
          ".": toPaste("›"),
        },
        withMapper(["←", "→", "↑", "↓", "␣", "⏎", "⌫", "⌦"])((k) =>
          map(k).toPaste(k),
        ),
      ]),
    );
}

function fg_hyper() {
  return duoLayer("f", "g", "fg Hyper")
    .leaderMode({
      escape: { simultaneous: [{ key_code: "k" }, { key_code: "j" }] },
    })
    .notification("Hyper Mode fg 🌈")
    .manipulators(
      appleKeyboardOnly([
        map("1").to("1", "Hyper"),
        map("2").to("2", "Hyper"),
        map("3").to("3", "Hyper"),
        map("f").to("f", "Hyper"),
        map("g").to("g", "Hyper"),
        map("j").to("j", "Hyper"),
        map("a").to("a", "Hyper"),
        map("n").to("n", "Hyper"),
        map("u").to("u", "Hyper"),
        map("w").to("w", "Hyper"),
        map("/").to("u", "Meh"),
      ]),
    );
}

function tab_hyper_rule() {
  return rule("Tab => Hyper").manipulators(
    appleKeyboardOnly([
      map("tab")
        .toIfAlone("tab")
        .toIfHeldDown({
          key_code: "right_command",
          modifiers: ["right_control", "right_option", "right_shift"],
        })
        .toDelayedAction(toKey("vk_none"), toKey("vk_none"))
        .parameters({
          "basic.to_if_alone_timeout_milliseconds": 500,
          "basic.to_if_held_down_threshold_milliseconds": 0,
        }),
    ]),
  );
}

function capslock_zoot_rule() {
  return rule("Capslock => Zoot (Ctrl+Option+Cmd)").manipulators(
    appleKeyboardOnly([
      map("caps_lock", { optional: "any" })
        .toIfAlone("escape")
        .toIfHeldDown({
          key_code: "right_command",
          modifiers: ["right_control", "right_option"],
        })
        .toDelayedAction(toKey("vk_none"), toKey("vk_none"))
        .parameters({
          "basic.to_if_alone_timeout_milliseconds": 500,
          "basic.to_if_held_down_threshold_milliseconds": 0,
        }),
    ]),
  );
}
