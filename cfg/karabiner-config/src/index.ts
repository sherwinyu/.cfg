import {
  FromAndToKeyCode,
  FromKeyParam,
  map,
  mapSimultaneous,
  rule,
  simlayer,
  toKey,
  ToKeyParam,
  toNotificationMessage,
  toRemoveNotificationMessage,
  withMapper,
  writeToProfile
} from 'karabiner.ts'

// TO RUN: `npm run build`

// ! Change '--dry-run' to your Karabiner-Elements Profile name.
// (--dry-run print the config json into console)
// + Create a new profile if needed.
writeToProfile('karabiner-config-profile', [
  // rule('z to ctrl').manipulators([
  //   map('z', 'optionalAny')
  //     .toIfAlone('z', {}, { halt: true })
  //     .toIfHeldDown('left_control')
  //     .toDelayedAction([], toKey('z'))
  //     .parameters({
  //       "basic.to_delayed_action_delay_milliseconds": 500,
  //       "basic.to_if_held_down_threshold_milliseconds": 200
  //     })
  // ]),


  // rule("A")
  //   .manipulators([
  //     withModifier('optionalAny')([
  //       map('a')
  //         .toIfAlone("a", {}, { halt: true })
  //         .toIfHeldDown("‹⇧"),
  //     ]),
  //   ]),
  // rule("easy mods").manipulators([
  //   withModifier('optionalAny')([
  //     map('z')
  //       .toIfAlone("z", {}, { halt: true })
  //       .toIfHeldDown("left_control"),
  //     map('/')
  //       .toIfAlone("/", {}, { halt: true })
  //       .toIfHeldDown("left_control"),
  //   ]),
  // ]),

  text_editing_layer(),
  nav_layer(),
  easy_mods_rules(),
  // symbol_layer(),
  rule('jk => Esc').manipulators([
    mapSimultaneous(['j', 'k']).to('escape'),
  ]),
  rule('Caps Lock → Hyper').manipulators([
    map('caps_lock').toHyper().toIfAlone('caps_lock'),
  ]),
])

function text_editing_layer() {
  return simlayer('e', 'text_editing').manipulators([
    map('a').to('a', 'command'),
    map('s').to('s', ['control', 'command']),
    map('p').to('left_arrow', 'command').to('right_arrow', ['shift', 'command']),
    map('k').to('up_arrow', 'control'),
    map('j').to('down_arrow', 'control')
  ])
}

function nav_layer() {
  return simlayer('d', 'nav')
    .toIfActivated(toNotificationMessage('simlayer-d', 'Navigation Mode'))
    .toIfDeactivated(toRemoveNotificationMessage('simlayer-d'))
    .manipulators([
      map('h').to('left_arrow'),
      map('l').to('right_arrow'),
      map('k').to('up_arrow'),
      map('j').to('down_arrow'),

      map('a').to('left_arrow', 'command'),
      map(';').to('right_arrow', 'command'),

      map('f').to('left_option'),
      map('s').to('left_shift'),
    ])
}


function easy_mods_rules() {
  return rule('easy mods').manipulators([
    withMapper<ToKeyParam, ToKeyParam>({
      'z': 'left_control',
      'slash': 'right_control',
      'f': 'left_option',
    })((lhs, rhs) => {
      return map(lhs as FromKeyParam, 'optionalAny')
        .toIfAlone(lhs as ToKeyParam, {}, { halt: true })
        .toIfHeldDown(rhs)
        .toDelayedAction([], toKey(lhs))
        .parameters({
          "basic.to_delayed_action_delay_milliseconds": 500,
          "basic.to_if_held_down_threshold_milliseconds": 160
        })
    })
  ])
}

