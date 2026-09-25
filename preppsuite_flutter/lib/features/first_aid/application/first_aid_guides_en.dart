import 'first_aid_guide.dart';
import 'poison_centres.dart';

/// The first aid guides in English.
///
/// Same ids, same order and the same number of steps as
/// `first_aid_guides_de.dart` — `first_aid_guides_test.dart` holds the two
/// files to that. A translation that quietly drops a step would be a
/// translation that quietly drops a step of a resuscitation.
///
/// The telephone numbers are the German ones, because the app is used in
/// Germany whatever language it is read in. 112 is the emergency number
/// across the European Union either way.
const firstAidGuidesEn = <FirstAidGuide>[
  FirstAidGuide(
    id: 'emergency-call',
    group: FirstAidGroup.basics,
    title: 'Making the call',
    when: 'First of all, as soon as somebody is in serious trouble.',
    steps: [
      FirstAidStep(
        'Where did it happen?',
        detail:
            'Town, street, number, floor. In the countryside: the '
            'village and what stands nearby.',
      ),
      FirstAidStep(
        'What happened?',
        detail:
            'One sentence is enough: fell off a roof, not breathing, '
            'car into a tree.',
      ),
      FirstAidStep('How many people are hurt?'),
      FirstAidStep(
        'What kind of injuries?',
        detail: 'What you can see, not what you suspect.',
      ),
      FirstAidStep(
        'Wait for questions.',
        detail:
            'The dispatcher ends the call, not you. They will talk '
            'you through what to do until the ambulance arrives.',
      ),
    ],
    facts: [
      FirstAidFact('Ambulance and fire brigade', '112'),
      FirstAidFact('Police', '110'),
      FirstAidFact('Out-of-hours doctor', '116 117'),
      FirstAidFact('Across Europe', '112'),
    ],
    cautions: [
      'Do not hang up until the dispatcher says so.',
      'No signal does not mean no emergency call: 112 works without '
          'credit and, in many cases, over another network.',
    ],
    source:
        'German Federal Office of Civil Protection and Disaster '
        'Assistance (BBK)',
  ),
  FirstAidGuide(
    id: 'unresponsive',
    group: FirstAidGroup.basics,
    title: 'Checking an unresponsive person',
    when:
        'Somebody is lying there and does not react. This is where '
        'everything else starts.',
    steps: [
      FirstAidStep(
        'Your own safety first.',
        detail:
            'Traffic, electricity, smoke, gas. A second casualty '
            'helps nobody.',
      ),
      FirstAidStep('Speak loudly and shake the shoulders.'),
      FirstAidStep(
        'No response? Shout for help and call 112.',
        detail: 'Put the phone on speaker so your hands stay free.',
      ),
      FirstAidStep(
        'Open the airway.',
        detail:
            'One hand on the forehead, two fingers of the other '
            'under the chin, tilt the head gently back.',
      ),
      FirstAidStep(
        'Look for breathing for no longer than 10 seconds.',
        detail:
            'Is the chest rising? Can you hear breath? Can you feel '
            'air on your cheek?',
      ),
      FirstAidStep(
        'Breathing normally: recovery position, and keep watching.',
      ),
      FirstAidStep(
        'Not breathing normally: start resuscitation at once.',
      ),
    ],
    cautions: [
      'Occasional gasps are not normal breathing. This agonal breathing '
          'is common in the first minutes of a cardiac arrest and is '
          'regularly mistaken for breathing — in doubt, treat it as no '
          'breathing.',
      'When in doubt, push. Chest compressions on somebody whose heart '
          'is still beating do far less harm than no resuscitation on '
          'somebody whose heart has stopped.',
    ],
    source: 'European Resuscitation Council (ERC) Guidelines 2025',
  ),
  FirstAidGuide(
    id: 'cpr-adult',
    group: FirstAidGroup.lifeThreatening,
    title: 'Resuscitation — adult',
    when: 'The person does not react and is not breathing normally.',
    callFirst: true,
    drawing: FirstAidDrawing.compressionPoint,
    hasPacer: true,
    steps: [
      FirstAidStep(
        'Call 112 and send someone for a defibrillator.',
        detail:
            'Alone: call first, speaker on, then push. With someone '
            'else: they call and fetch the AED, you push.',
      ),
      FirstAidStep(
        'Start where the person is lying.',
        detail:
            'Open clothing only if you cannot find the pressure point '
            'otherwise. Move them onto a firm surface only if it takes '
            'seconds — any delay costs more than the soft surface.',
      ),
      FirstAidStep(
        'Heel of one hand on the centre of the chest, the other hand on '
        'top, fingers interlocked.',
        detail:
            'Centre of the chest means the lower half of the '
            'breastbone.',
      ),
      FirstAidStep(
        'Push 30 times.',
        detail:
            '5 to 6 cm deep, 100 to 120 times a minute, arms '
            'straight, vertically from above. Let the chest come all the '
            'way back up after each push.',
      ),
      FirstAidStep(
        'Give 2 rescue breaths.',
        detail:
            'Head tilted back, nose pinched, blow steadily for one '
            'second until the chest visibly rises. No more than 10 '
            'seconds for both.',
      ),
      FirstAidStep(
        'Carry on 30:2 without a break.',
        detail:
            'Until the ambulance takes over, an AED tells you to '
            'stand clear, or the person starts breathing normally.',
      ),
      FirstAidStep(
        'With two of you, swap every two minutes.',
        detail:
            'The swap takes seconds. Tired hands push too shallow '
            'without anyone noticing.',
      ),
    ],
    facts: [
      FirstAidFact('Rate', '100–120 per minute'),
      FirstAidFact('Depth', '5–6 cm'),
      FirstAidFact('Ratio', '30 compressions : 2 breaths'),
    ],
    cautions: [
      'If you cannot or will not give breaths, keep pushing without '
          'stopping. Compression-only is markedly better than nothing.',
      'Do not stop to check whether it is working. Every interruption '
          'lets the pressure in the circulation collapse.',
      'Cracking sounds are normal and are not a reason to stop.',
    ],
    source: 'European Resuscitation Council (ERC) Guidelines 2025',
  ),
  FirstAidGuide(
    id: 'cpr-child',
    group: FirstAidGroup.lifeThreatening,
    title: 'Resuscitation — child and infant',
    when:
        'A pre-pubescent child or an infant does not react and is not '
        'breathing normally.',
    callFirst: true,
    hasPacer: true,
    steps: [
      FirstAidStep(
        'Call 112 as soon as the child does not react and is not '
        'breathing normally.',
        detail:
            'Speaker on, phone down — you stay with the child and keep '
            'your hands free. Until 2021 the rule here was one minute of '
            'resuscitation first; since the 2025 guidelines the order is '
            'the same as for an adult.',
      ),
      FirstAidStep(
        'Start with 5 rescue breaths, not with compressions.',
        detail:
            'In children the heart nearly always stops for want of '
            'oxygen, not the other way round. On an infant, seal your '
            'mouth over mouth and nose together.',
      ),
      FirstAidStep(
        'Push 15 times, then give 2 breaths.',
        detail:
            'Child: one or two heels of the hand. Infant: two '
            'fingers, or both thumbs with your hands encircling the '
            'chest.',
      ),
      FirstAidStep(
        'Push a third of the depth of the chest.',
        detail:
            'About 5 cm in a child, about 4 cm in an infant. Same '
            'rate as an adult: 100 to 120 a minute.',
      ),
      FirstAidStep('Carry on 15:2 until help arrives.'),
    ],
    facts: [
      FirstAidFact('First', '5 rescue breaths'),
      FirstAidFact('Then', '15 compressions : 2 breaths'),
      FirstAidFact('Depth, child', 'about 5 cm'),
      FirstAidFact('Depth, infant', 'about 4 cm'),
      FirstAidFact('Rate', '100–120 per minute'),
    ],
    cautions: [
      'If 15:2 is more than you trust yourself with, use 30:2 as for an '
          'adult. That is expressly allowed and far better than '
          'hesitating.',
      'Pushing too gently is the commonest mistake. A child whose heart '
          'has stopped cannot be saved by timid compressions.',
    ],
    source: 'European Resuscitation Council (ERC) Guidelines 2025',
  ),
  FirstAidGuide(
    id: 'aed',
    group: FirstAidGroup.lifeThreatening,
    title: 'Defibrillator (AED)',
    when: 'A device is within reach while resuscitation is under way.',
    steps: [
      FirstAidStep('Switch it on. From now on it talks you through it.'),
      FirstAidStep(
        'Keep pushing while the pads go on.',
        detail: 'Only break off if you are on your own.',
      ),
      FirstAidStep(
        'Stick the pads on the bare chest as printed on them.',
        detail:
            'One below the right collarbone, one on the left side '
            'below the armpit. Chest wet? Dry it first.',
      ),
      FirstAidStep('Touch nobody while it analyses.'),
      FirstAidStep(
        'Shock advised: make sure nobody is touching the person, then '
        'press.',
      ),
      FirstAidStep(
        'Go straight back to compressions.',
        detail:
            'Without waiting for a reaction. The device speaks up '
            'again after two minutes by itself.',
      ),
    ],
    cautions: [
      'An AED never shocks somebody who does not need it. It analyses '
          'by itself and only then releases the button.',
      'Children under eight: use paediatric pads if there are any. If '
          'there are none, use the adult pads — better than no shock.',
      'Do not put a pad over a pacemaker; a few centimetres to the side '
          'is enough. Peel off any medication patches first.',
    ],
    source: 'European Resuscitation Council (ERC) Guidelines 2025',
  ),
  FirstAidGuide(
    id: 'recovery-position',
    group: FirstAidGroup.lifeThreatening,
    title: 'Recovery position',
    when: 'The person is unconscious and breathing normally.',
    drawing: FirstAidDrawing.recoveryPosition,
    steps: [
      FirstAidStep('Kneel beside them and straighten their legs.'),
      FirstAidStep(
        'Place the near arm at a right angle, palm upwards.',
      ),
      FirstAidStep(
        'Bring the far arm across the chest, hold the back of that hand '
        'against the near cheek and keep it there.',
      ),
      FirstAidStep(
        'Bend the far knee up and pull them towards you by that knee.',
      ),
      FirstAidStep(
        'Arrange the upper leg so hip and knee are both at right '
        'angles.',
      ),
      FirstAidStep(
        'Tilt the head back so the airway stays open and the mouth is '
        'the lowest point.',
      ),
      FirstAidStep(
        'Keep watching the breathing.',
        detail:
            'If it stops or turns abnormal: roll them onto their '
            'back and start resuscitation.',
      ),
    ],
    cautions: [
      'Turn them onto the other side after 30 minutes at the latest.',
      'With a suspected spinal injury, only turn them if the airway '
          'cannot be kept open any other way. The airway comes first.',
    ],
    source: 'European Resuscitation Council (ERC) Guidelines 2025',
  ),
  FirstAidGuide(
    id: 'choking',
    group: FirstAidGroup.lifeThreatening,
    title: 'Choking',
    when:
        'Somebody clutches their throat, cannot speak, cannot cough, '
        'cannot breathe.',
    drawing: FirstAidDrawing.choking,
    steps: [
      FirstAidStep(
        'Still coughing hard: tell them to keep coughing and stay with '
        'them.',
        detail: 'A cough is stronger than anything you can do.',
      ),
      FirstAidStep(
        'The cough weakens: 5 blows between the shoulder blades.',
        detail:
            'Lean them forward, strike firmly with the heel of your '
            'hand, check after each one.',
      ),
      FirstAidStep(
        'Still stuck: 5 abdominal thrusts.',
        detail:
            'From behind, a fist between navel and the bottom of the '
            'breastbone, grasp it with the other hand, pull sharply in '
            'and up.',
      ),
      FirstAidStep('Carry on alternating: 5 blows, 5 thrusts.'),
      FirstAidStep(
        'If they become unconscious: 112 and start resuscitation.',
      ),
    ],
    facts: [
      FirstAidFact('Alternate', '5 back blows, 5 abdominal thrusts'),
      FirstAidFact('Infant', '5 back blows, 5 chest thrusts'),
    ],
    cautions: [
      'No abdominal thrusts on an infant under one year. Instead 5 back '
          'blows face-down along your forearm, then 5 chest thrusts '
          'face-up.',
      'Do not sweep blindly in the mouth with your fingers. That '
          'usually pushes the object deeper.',
      'After abdominal thrusts always have them checked by a doctor, '
          'even if all seems well — internal injuries are possible.',
    ],
    source: 'European Resuscitation Council (ERC) Guidelines 2025',
  ),
  FirstAidGuide(
    id: 'drowning',
    group: FirstAidGroup.lifeThreatening,
    title: 'Drowning',
    when: 'Somebody is in trouble in the water, or has just been got out.',
    steps: [
      FirstAidStep(
        'Do not go into the water.',
        detail:
            'Somebody actively drowning holds on and pulls the helper '
            'under. Help from the bank or from a boat.',
      ),
      FirstAidStep(
        'Reach out with something rigid, or throw something that floats.',
        detail: 'A pole, a branch, an oar, a rope, a ring buoy.',
      ),
      FirstAidStep('Call 112.'),
      FirstAidStep('On land, speak to them loudly and check the breathing.'),
      FirstAidStep(
        'Not breathing normally: resuscitate at once, 30 compressions and '
        '2 rescue breaths.',
        detail:
            'With drowning the rescue breaths belong to it — unlike a '
            'cardiac arrest. Start with the compressions all the same.',
      ),
      FirstAidStep('Defibrillator: dry the skin before the pads go on.'),
      FirstAidStep(
        'Breathing normally: recovery position, head placed so that fluid '
        'can drain from the mouth.',
      ),
      FirstAidStep(
        'Take vomit or debris out only where it is genuinely blocking the '
        'breathing.',
      ),
    ],
    facts: [FirstAidFact('Ratio', '30 compressions, 2 breaths')],
    cautions: [
      'No resuscitation in the water. That is for rescuers specifically '
          'and repeatedly trained for it, not for a bystander.',
      'Do not take hold of somebody who is actively drowning.',
      'No pressure on the chest that makes breathing harder.',
    ],
    source:
        'International first aid, resuscitation and education guidelines '
        '2025 (IFRC), "Drowning"',
  ),
  FirstAidGuide(
    id: 'severe-bleeding',
    group: FirstAidGroup.injury,
    title: 'Severe bleeding',
    when: 'Blood is flowing hard, spurting, or soaking through clothing.',
    callFirst: true,
    drawing: FirstAidDrawing.bleeding,
    steps: [
      FirstAidStep(
        'Press directly on the wound, at once.',
        detail:
            'With your hand, with a cloth, with whatever is there. '
            'Gloves only if they are within reach.',
      ),
      FirstAidStep('Call 112, or have someone call.'),
      FirstAidStep('Raise the bleeding part if you can.'),
      FirstAidStep(
        'Put on a pressure dressing and keep the pressure on.',
        detail:
            'Bleeding through: do not take it off, add another layer '
            'over it and keep pressing.',
      ),
      FirstAidStep(
        'If bleeding from an arm or leg cannot be stopped that way: '
        'tourniquet.',
        detail:
            '5 to 7 cm above the wound, never over a joint. Tight '
            'enough that the bleeding stops. Write the time on the skin.',
      ),
      FirstAidStep(
        'Lay them flat and keep them warm.',
        detail: 'Watch for signs of shock.',
      ),
    ],
    cautions: [
      'A tourniquet once applied stays on until medical staff remove '
          'it. Loosening and retightening is more dangerous than leaving '
          'it.',
      'Do not lift the dressing to look. Every look tears open the '
          'clotting that has just formed.',
      'Do not pull out an embedded object. It is plugging the wound it '
          'made. Pad around it instead.',
    ],
    source:
        'European Resuscitation Council (ERC) First Aid Guidelines '
        '2025',
  ),
  FirstAidGuide(
    id: 'shock',
    group: FirstAidGroup.injury,
    title: 'Shock',
    when:
        'Pale, cold clammy skin, fast shallow pulse, restless or '
        'strikingly apathetic — after blood loss, burns or severe pain.',
    callFirst: true,
    steps: [
      FirstAidStep('Call 112.'),
      FirstAidStep(
        'Deal with the cause as far as you can.',
        detail:
            'Stop the bleeding first. Without that, positioning does '
            'little.',
      ),
      FirstAidStep(
        'Lay them flat and raise the legs about 30 cm.',
        detail:
            'Not with a suspected spine, pelvis or leg injury, and '
            'not if they are struggling to breathe.',
      ),
      FirstAidStep(
        'Keep them warm.',
        detail:
            'A blanket under them as well as over them. The ground '
            'takes more heat than the air.',
      ),
      FirstAidStep('Stay, talk to them, watch the breathing.'),
    ],
    cautions: [
      'Nothing to eat and nothing to drink, however firmly they ask. '
          'Surgery may be ahead.',
      'If they lose consciousness and breathe normally: recovery '
          'position. If they do not breathe normally: resuscitation.',
    ],
    source:
        'European Resuscitation Council (ERC) First Aid Guidelines '
        '2025',
  ),
  FirstAidGuide(
    id: 'amputation',
    group: FirstAidGroup.injury,
    title: 'Severed body part',
    when: 'A finger, a hand, a foot is off, wholly or partly.',
    steps: [
      FirstAidStep('Call 112.'),
      FirstAidStep(
        'If it is bleeding heavily: stop the bleeding first as for severe '
        'bleeding, and treat the person for shock.',
      ),
      FirstAidStep(
        'Partly severed: keep the limb as still as possible, preferably in '
        'normal alignment, and cover it with a sterile dressing or clean '
        'cloth.',
      ),
      FirstAidStep(
        'Completely severed: cover the wound with a sterile dressing or '
        'clean cloth.',
      ),
      FirstAidStep(
        'Keep the severed part dry and cool.',
        detail:
            'Into a clean, watertight bag, sealed firmly, and that bag '
            'into a larger container of ice and water. Send it with the '
            'person to the hospital.',
      ),
      FirstAidStep(
        'Stay with the person and think of them, not only of the wound.',
        detail:
            'Psychological first aid applies here to the injured, to '
            'their family — and to you.',
      ),
    ],
    cautions: [
      'Not straight into water and not straight onto ice. That damages '
          'the tissue and can make reattachment impossible.',
      'This is a large open wound. Mind your own protection.',
    ],
    source:
        'International first aid, resuscitation and education guidelines '
        '2025 (IFRC), "Amputation"',
  ),
  FirstAidGuide(
    id: 'chest-abdomen-injury',
    group: FirstAidGroup.injury,
    title: 'Chest or abdomen injury',
    when: 'A stab, a gunshot, an impalement or blunt force to the trunk.',
    steps: [
      FirstAidStep(
        'Abdomen: lying flat with the knees drawn up.',
        detail: 'That takes the tension out of the abdominal wall.',
      ),
      FirstAidStep(
        'Chest: sitting, leaning slightly towards the injured side.',
        detail: 'That is how the good lung works best.',
      ),
      FirstAidStep('Control bleeding with pressure.'),
      FirstAidStep('Call 112.'),
      FirstAidStep(
        'Cover an abdominal wound with a clean dressing once the bleeding '
        'is controlled.',
        detail:
            'If organs are bulging out, do not push them back — cover '
            'them with a clean, wet dressing.',
      ),
      FirstAidStep(
        'Reassure them and watch breathing, circulation and response, '
        'particularly for signs of shock.',
      ),
    ],
    cautions: [
      'Do not seal an open chest wound airtight. Air then builds up '
          'inside the chest.',
      'When pressing on a chest wound, do not close the wound completely.',
    ],
    source:
        'International first aid, resuscitation and education guidelines '
        '2025 (IFRC), "Chest and abdomen injuries"',
  ),
  FirstAidGuide(
    id: 'burns',
    group: FirstAidGroup.injury,
    title: 'Burns and scalds',
    when:
        'Heat, fire, hot liquid, electricity or chemicals have injured '
        'the skin.',
    steps: [
      FirstAidStep(
        'Stop the cause.',
        detail:
            'Smother flames, switch off the power, take off hot '
            'soaked clothing as long as it is not stuck.',
      ),
      FirstAidStep(
        'Cool small areas for 10 to 20 minutes.',
        detail:
            'Running lukewarm water, around 20 °C. Hands, feet, face '
            'or single patches only.',
      ),
      FirstAidStep(
        'Take off rings, watches and bracelets straight away.',
        detail: 'Before it swells. Afterwards it is too late.',
      ),
      FirstAidStep(
        'Cover loosely with something clean.',
        detail:
            'A burn dressing or a clean cloth. Nothing that sheds '
            'fibres.',
      ),
      FirstAidStep(
        'Do not cool large areas — cover them and keep the person warm.',
        detail:
            'More than the casualty’s own palm. Cooling then '
            'causes hypothermia, which is more dangerous than the burn.',
      ),
      FirstAidStep(
        'Call 112 for large areas, for face, hands, genitals or joints, '
        'for children, and for electrical and chemical burns.',
      ),
    ],
    cautions: [
      'No ice, no iced water. That does further damage.',
      'Do not open blisters.',
      'No ointment, no oil, no flour, no powder, no home remedy.',
      'Do not pull off clothing that has stuck. Cut around it rather '
          'than tearing it away.',
    ],
    source:
        'European Resuscitation Council (ERC) First Aid Guidelines '
        '2025',
  ),
  FirstAidGuide(
    id: 'fracture',
    group: FirstAidGroup.injury,
    title: 'Fracture, sprain, strain',
    when: 'After a fall or a blow: pain, swelling, a limb out of shape.',
    steps: [
      FirstAidStep('Keep the injured part still.'),
      FirstAidStep(
        'Support it in a comfortable position so nothing moves.',
        detail: 'Keeping it raised can reduce the swelling.',
      ),
      FirstAidStep(
        'Cool it for up to 20 minutes.',
        detail:
            'Longer damages the skin. As soon after the injury as you can, '
            'and always wrap the cold pack in a cloth.',
      ),
      FirstAidStep(
        'Call 112 for a lot of pain, a lot of swelling, signs of shock, a '
        'fracture of the thigh bone, or a limb in an abnormal position.',
      ),
      FirstAidStep(
        'Open fracture: stop the bleeding first, then stabilize the limb.',
      ),
    ],
    facts: [FirstAidFact('Cooling', '20 minutes at most')],
    cautions: [
      'Never put a cold pack straight onto the skin.',
      'Stop cooling if it becomes too painful. If the pain returns and the '
          'skin is back to its normal temperature, you may cool again.',
      'Fractures and dislocations always belong in medical hands. In doubt '
          'whether it is a fracture, a sprain or a strain: see a doctor.',
    ],
    source:
        'International first aid, resuscitation and education guidelines '
        '2025 (IFRC), "Fractures, sprains and strains"',
  ),
  FirstAidGuide(
    id: 'spinal-injury',
    group: FirstAidGroup.injury,
    title: 'Suspected spinal injury',
    when:
        'A fall from height, a dive, a road collision — and pain in the '
        'neck or back.',
    steps: [
      FirstAidStep('Do not move them. They stay as you found them.'),
      FirstAidStep(
        'If they are responsive: reassure them and ask them to stay as '
        'still as they can.',
      ),
      FirstAidStep(
        'For a child, for somebody drowsy, or where somebody cannot '
        'follow: support the head gently.',
        detail: 'So that neck and spine do not move.',
      ),
      FirstAidStep('Call 112.'),
      FirstAidStep(
        'Unresponsive and breathing normally: leave them, open the airway '
        'and support the head in that position.',
      ),
      FirstAidStep(
        'Keep them warm and watch breathing and response until the '
        'ambulance arrives.',
      ),
    ],
    facts: [FirstAidFact('If they must be moved', 'at least two helpers')],
    cautions: [
      'Do not reposition them while the breathing is normal and there is '
          'no danger.',
      'If they must be moved after all, for danger: at least two helpers, '
          'one keeping the head in line with the spine.',
      'With a suspected pelvic fracture, do not rock or rotate the pelvis '
          '— that can restart bleeding.',
    ],
    source:
        'International first aid, resuscitation and education guidelines '
        '2025 (IFRC), "Spinal injury"',
  ),
  FirstAidGuide(
    id: 'head-injury',
    group: FirstAidGroup.injury,
    title: 'Head injury and concussion',
    when: 'A blow to the head, or a fall onto it.',
    steps: [
      FirstAidStep('Take them out of the activity and have them rest.'),
      FirstAidStep(
        'Watch for the signs of concussion, and for any change in response '
        'and breathing.',
      ),
      FirstAidStep(
        'Severe head injury: call 112, reassure them, keep head and neck '
        'as still as possible.',
        detail:
            'If they are lying down you can hold the head still with your '
            'hands or knees.',
      ),
      FirstAidStep(
        'Watch response and breathing until the ambulance arrives.',
      ),
    ],
    cautions: [
      'Not every knock on the head is a concussion. Where the signs are '
          'absent or mild, rest helps — they still have to be watched.',
      'A concussion can develop over hours or days.',
      'Back to work, the wheel, machinery or sport only once the signs '
          'have gone.',
    ],
    source:
        'International first aid, resuscitation and education guidelines '
        '2025 (IFRC), "Head injury and concussion"',
  ),
  FirstAidGuide(
    id: 'cuts-and-grazes',
    group: FirstAidGroup.injury,
    title: 'Cuts and grazes',
    when: 'The small injury there is most of.',
    steps: [
      FirstAidStep(
        'If it is bleeding heavily: pressure on the wound first, then on '
        'from here.',
      ),
      FirstAidStep(
        'Rinse with clean drinking water, lukewarm and from a tap if you '
        'can.',
        detail:
            'No tap: pierce a clean, unused water bottle — that gives a '
            'gentle stream.',
      ),
      FirstAidStep(
        'Take out what dirt is left with water and a clean compress.',
      ),
      FirstAidStep(
        'Dry the skin around it and cover the wound.',
        detail: 'A dressing, film, hydrocolloid — or simply a plaster.',
      ),
    ],
    facts: [FirstAidFact('Tetanus after a dirty wound', 'every 5 years')],
    cautions: [
      'If tetanus cover is uncertain, see a doctor. After a dirty wound a '
          'booster counts every five years, otherwise every ten.',
      'Change the dressing only when it is visibly soaked through. While '
          'it is clean, it stays on.',
    ],
    source:
        'International first aid, resuscitation and education guidelines '
        '2025 (IFRC), "Cuts and grazes"',
  ),
  FirstAidGuide(
    id: 'nosebleed',
    group: FirstAidGroup.injury,
    title: 'Nosebleed',
    when: 'Blood from the nose, by itself or after a knock.',
    steps: [
      FirstAidStep(
        'Sit down and tip the head slightly forward.',
        detail: 'Forward, not back.',
      ),
      FirstAidStep(
        'Pinch the nostrils together, 10 to 15 minutes without letting go.',
      ),
      FirstAidStep(
        'If it has not stopped after 15 minutes, or they go lightheaded '
        'from the blood loss: medical help.',
      ),
      FirstAidStep(
        'After a blow, with signs of a brain injury, a misshapen nose, a '
        'facial fracture — or if they take anticoagulants: call 112 at '
        'once.',
      ),
    ],
    facts: [FirstAidFact('Pinching', '10 to 15 minutes without letting go')],
    cautions: [
      'Do not tip the head back. The blood then runs down the throat.',
      'See a doctor if they come often in a short time — or if a child '
          'under two has had one.',
    ],
    source:
        'International first aid, resuscitation and education guidelines '
        '2025 (IFRC), "Nosebleeds"',
  ),
  FirstAidGuide(
    id: 'animal-bite',
    group: FirstAidGroup.injury,
    title: 'Animal bite',
    when: 'Bitten by a dog, a cat or a wild animal.',
    steps: [
      FirstAidStep('If it is bleeding: pressure on the wound first.'),
      FirstAidStep('Then as for a wound: rinse it and cover it.'),
      FirstAidStep(
        'See a doctor if the wound needs closing or tetanus cover is '
        'missing.',
      ),
      FirstAidStep(
        'From a wild animal, without rabies cover: seek medical care.',
      ),
    ],
    cautions: [
      'Animal bites can pass on disease. Even a small bite is not an '
          'ordinary small wound.',
      'Watch for infection: if it becomes warm or more painful, see a '
          'doctor.',
    ],
    source:
        'International first aid, resuscitation and education guidelines '
        '2025 (IFRC), "Mammal bites"',
  ),
  FirstAidGuide(
    id: 'tick',
    group: FirstAidGroup.injury,
    title: 'Tick bite',
    when: 'A tick is sitting in the skin.',
    steps: [
      FirstAidStep(
        'Get it out as quickly as you can.',
        detail:
            'With a tick card or tool, following its instructions. '
            'Otherwise grip it with tweezers as close to the skin as '
            'possible and pull it out steadily and firmly.',
      ),
      FirstAidStep('Wash the site with soap and water.'),
      FirstAidStep(
        'Write down the date and where it happened, and keep an eye on the '
        'spot.',
      ),
      FirstAidStep(
        'See a doctor for fever, unexplained tiredness, joint pain, or if '
        'a rash appears.',
        detail:
            'The Lyme rash is a patch with a ring around it. It does not '
            'always appear.',
      ),
    ],
    cautions: [
      'Do not squeeze the tick\'s body. That pushes the organisms into '
          'the skin.',
      'No chemicals and no heat to stun or kill it.',
      'A tick bite is treated differently from a snakebite.',
    ],
    source:
        'International first aid, resuscitation and education guidelines '
        '2025 (IFRC), "Insect bites or stings"',
  ),
  FirstAidGuide(
    id: 'insect-bite',
    group: FirstAidGroup.injury,
    title: 'Insect sting',
    when: 'Bee, wasp, hornet, mosquito.',
    steps: [
      FirstAidStep('Reassure them and keep them from scratching.'),
      FirstAidStep(
        'If the stinger is still in: out as fast as possible.',
        detail:
            'Scrape it off with something flat — a bank card, the blunt '
            'side of a knife.',
      ),
      FirstAidStep('Clean the site thoroughly with water.'),
      FirstAidStep(
        'Cool it, against swelling, itching and pain.',
        detail: 'If it is on the hand: take the rings off.',
      ),
      FirstAidStep(
        'Call 112 at once for a sting in the mouth or throat, or at any '
        'sign of an allergic reaction.',
        detail:
            'In the mouth the swelling can close the airway. While you '
            'wait, let them suck an ice cube.',
      ),
    ],
    cautions: [
      'Do not take the stinger with tweezers or fingers. That squeezes '
          'the venom sac.',
      'No scratching.',
      'Breathlessness, a swelling face or circulatory trouble make it '
          'anaphylaxis — see its own guide.',
    ],
    source:
        'International first aid, resuscitation and education guidelines '
        '2025 (IFRC), "Insect bites or stings"',
  ),
  FirstAidGuide(
    id: 'snakebite',
    group: FirstAidGroup.injury,
    title: 'Snakebite',
    when: 'In Germany the adder — or a snake somebody keeps.',
    steps: [
      FirstAidStep('Away from the snake, somewhere safe.'),
      FirstAidStep(
        'Have them lie down comfortably and move as little as possible.',
      ),
      FirstAidStep('Call 112.'),
      FirstAidStep(
        'Take off jewellery, watch and tight clothing before it swells.',
        detail: 'Moving the limb as little as you can while you do.',
      ),
      FirstAidStep('Mark the bite and note the time.'),
      FirstAidStep(
        'Watch response and breathing, talk to them calmly and stay.',
      ),
    ],
    cautions: [
      'None of this helps and all of it can harm: a tourniquet, sucking '
          'the venom out, a cold compress, rubbing the bite, cutting it '
          'open.',
      'Snakes are traded and travel. It may be a species that does not '
          'belong here.',
    ],
    source:
        'International first aid, resuscitation and education guidelines '
        '2025 (IFRC), "Snakebites"',
  ),
  FirstAidGuide(
    id: 'jellyfish',
    group: FirstAidGroup.injury,
    title: 'Jellyfish sting',
    when: 'Burning weals after swimming in the sea.',
    steps: [
      FirstAidStep(
        'Take the stinging cells off the skin, protecting yourself as you '
        'do.',
      ),
      FirstAidStep('Rinse the area with seawater.'),
      FirstAidStep(
        'Heat on the area, 20 to 30 minutes.',
        detail:
            'Warm water or a heat pack, 45 °C at most. Hot enough against '
            'the pain, not so hot that it burns.',
      ),
      FirstAidStep(
        'See a doctor where there is a tetanus risk or the pain stays.',
      ),
    ],
    facts: [FirstAidFact('Heat', '45 °C at most, 20 to 30 minutes')],
    cautions: [
      'Do not rinse with fresh water — seawater.',
      'For a severe allergic reaction, call 112 at once.',
    ],
    source:
        'International first aid, resuscitation and education guidelines '
        '2025 (IFRC), "Aquatic animal injuries"',
  ),
  FirstAidGuide(
    id: 'blisters',
    group: FirstAidGroup.injury,
    title: 'Blisters on the feet',
    when:
        'After a long walk — and so the injury that ends an evacuation on '
        'foot.',
    steps: [
      FirstAidStep(
        'Wash the blister and the skin around it with clean water and pat '
        'it dry gently.',
      ),
      FirstAidStep('If the blister is intact: cover it with a blister pad.'),
      FirstAidStep(
        'If it has drained by itself: clean the wound and cover it with a '
        'sterile dressing.',
        detail:
            'If they have to keep walking, a second layer of padding on '
            'top helps.',
      ),
    ],
    cautions: [
      'See a doctor if it becomes an open wound or shows infection — hot, '
          'increasingly painful, fever.',
      'With diabetes or a weakened immune system, see a doctor sooner: '
          'such wounds infect more easily and heal worse.',
    ],
    source:
        'International first aid, resuscitation and education guidelines '
        '2025 (IFRC), "Friction blisters"',
  ),
  FirstAidGuide(
    id: 'dental-avulsion',
    group: FirstAidGroup.injury,
    title: 'Knocked-out tooth',
    when: 'An adult tooth has come out whole.',
    steps: [
      FirstAidStep(
        'Stop the bleeding in the mouth with a compress of gauze or clean '
        'cotton.',
      ),
      FirstAidStep(
        'Find the tooth and pick it up by the crown only, not the root.',
      ),
      FirstAidStep(
        'Keep it moist.',
        detail:
            'Saline, a rehydration solution or clingfilm — with clingfilm, '
            'add enough of their saliva so the tooth does not dry out. '
            'Otherwise milk or their own saliva.',
      ),
      FirstAidStep(
        'To a dentist or emergency department as fast as possible, taking '
        'the tooth.',
      ),
    ],
    cautions: [
      'Do not carry the tooth in the mouth unless the person is an adult, '
          'fully awake and can do it safely. A clear airway comes before '
          'everything.',
      'A knocked-out tooth can point to another injury — to the head, for '
          'instance. That comes first.',
    ],
    source:
        'International first aid, resuscitation and education guidelines '
        '2025 (IFRC), "Dental avulsion"',
  ),
  FirstAidGuide(
    id: 'flash-eye',
    group: FirstAidGroup.injury,
    title: 'Flash eye',
    when:
        'Hours after welding, a sunbed, snow or the sea: pain, as though '
        'there were sand in the eye.',
    steps: [
      FirstAidStep('Away from the light source, and reassure them.'),
      FirstAidStep('Have them take contact lenses out.'),
      FirstAidStep(
        'Spare the eyes: stay indoors, sunglasses, eyes closed as much as '
        'possible.',
        detail:
            'A cool, damp cloth over the closed lids. Saline or eye drops '
            'keep them moist.',
      ),
      FirstAidStep(
        'If it is no better in 24 hours, or gets worse: see a doctor.',
      ),
    ],
    cautions: [
      'No rubbing.',
      'This is not only a snow thing — it happens by water, on a beach '
          'and at a welding bench.',
    ],
    source:
        'International first aid, resuscitation and education guidelines '
        '2025 (IFRC), "Flash eye"',
  ),
  FirstAidGuide(
    id: 'stroke',
    group: FirstAidGroup.illness,
    title: 'Stroke',
    when:
        'Sudden: a drooping mouth, a weak arm, slurred speech, '
        'disturbed vision, or the worst headache out of nowhere.',
    callFirst: true,
    drawing: FirstAidDrawing.face,
    steps: [
      FirstAidStep('Ask them to smile.', detail: 'Does one side droop?'),
      FirstAidStep(
        'Ask them to raise both arms in front, palms up.',
        detail: 'Does one drift down or rotate?',
      ),
      FirstAidStep(
        'Ask them to repeat a simple sentence.',
        detail: 'Is it slurred, or are words swapped around?',
      ),
      FirstAidStep(
        'Any one of them wrong: call 112 now.',
        detail: 'And say you think it is a stroke.',
      ),
      FirstAidStep(
        'Note the time it started.',
        detail:
            'That is the most important thing you can tell them — it '
            'decides the treatment. If they woke up like this, the time '
            'is when they were last seen well.',
      ),
      FirstAidStep(
        'Sit them up slightly if they are conscious.',
      ),
    ],
    facts: [
      FirstAidFact('F — Face', 'the face droops'),
      FirstAidFact('A — Arms', 'an arm drifts down'),
      FirstAidFact('S — Speech', 'speech is slurred'),
      FirstAidFact('T — Time', 'call 112 now, note the time'),
    ],
    cautions: [
      'Nothing to eat and nothing to drink. Swallowing can be impaired '
          'without it being visible.',
      'Do not wait to see whether it gets better. Even if the signs go '
          'away again it is an emergency.',
      'Do not drive them, and do not let them drive.',
    ],
    source:
        'European Resuscitation Council (ERC) First Aid Guidelines '
        '2025',
  ),
  FirstAidGuide(
    id: 'heart-attack',
    group: FirstAidGroup.illness,
    title: 'Heart attack',
    when:
        'Pressure, tightness or pain in the chest for more than a few '
        'minutes — often with breathlessness, nausea, cold sweat and '
        'fear.',
    callFirst: true,
    steps: [
      FirstAidStep('Call 112 now. Do not wait it out.'),
      FirstAidStep('Sit them up, half upright.'),
      FirstAidStep('Loosen tight clothing, open a window.'),
      FirstAidStep(
        'Stay with them and talk calmly.',
        detail:
            'Fear drives the pulse, and with it the heart’s '
            'demand for oxygen.',
      ),
      FirstAidStep(
        'Avoid every exertion.',
        detail: 'Do not let them walk, do not let them climb stairs.',
      ),
      FirstAidStep(
        'Unconscious and not breathing normally: start resuscitation.',
      ),
    ],
    cautions: [
      'In women, older people and diabetics the typical chest pain is '
          'often missing. Breathlessness, nausea, upper abdominal pain '
          'or sudden exhaustion come to the fore instead.',
      'Do not drive to hospital yourselves. Treatment starts in the '
          'ambulance; it does not start in your car.',
      'Give no medication that was not prescribed for this person.',
    ],
    source:
        'European Resuscitation Council (ERC) First Aid Guidelines '
        '2025',
  ),
  FirstAidGuide(
    id: 'seizure',
    group: FirstAidGroup.illness,
    title: 'Seizure',
    when:
        'Somebody falls, goes stiff and jerks, often with the eyes '
        'rolled back and saliva at the mouth.',
    steps: [
      FirstAidStep('Make room and move dangerous things away.'),
      FirstAidStep('Put something soft under the head.'),
      FirstAidStep(
        'Look at the clock.',
        detail: 'How long it lasts is the first thing you will be asked.',
      ),
      FirstAidStep(
        'Wait for it to pass.',
        detail: 'Most seizures stop by themselves after a minute or two.',
      ),
      FirstAidStep(
        'Afterwards: recovery position, and stay.',
        detail:
            'The confusion afterwards often lasts longer than the '
            'seizure did.',
      ),
    ],
    facts: [
      FirstAidFact('Call 112 if', 'it lasts longer than 5 minutes'),
      FirstAidFact('Also if', 'it is a first seizure'),
      FirstAidFact(
        'Also if',
        'a second follows without them coming round '
            'in between',
      ),
      FirstAidFact('Also for', 'injury, pregnancy, water'),
    ],
    cautions: [
      'Put nothing in the mouth. Nothing. The tongue cannot be '
          'swallowed; broken teeth and broken fingers can happen.',
      'Do not hold them down and do not try to stop the jerking.',
      'Nothing to drink until they are properly clear again.',
    ],
    source:
        'European Resuscitation Council (ERC) First Aid Guidelines '
        '2025',
  ),
  FirstAidGuide(
    id: 'anaphylaxis',
    group: FirstAidGroup.illness,
    title: 'Anaphylaxis',
    when:
        'After a sting, a nut, a drug or a food: weals, a swelling '
        'face, wheezing, a tight throat, a collapsing circulation.',
    callFirst: true,
    steps: [
      FirstAidStep('Call 112 now and say it is an allergic reaction.'),
      FirstAidStep(
        'Ask for their emergency kit, or look for it.',
        detail:
            'Anyone who knows about it usually carries an '
            'auto-injector.',
      ),
      FirstAidStep(
        'Press the auto-injector into the outer thigh.',
        detail:
            'Through clothing is fine. The instructions are on the '
            'device and take seconds to read.',
      ),
      FirstAidStep(
        'Lay them flat, legs up.',
        detail:
            'If they are struggling to breathe, let them sit '
            'upright instead. Do not let them stand up suddenly.',
      ),
      FirstAidStep(
        'No better after 5 to 15 minutes: a second dose, if there is a '
        'second one.',
      ),
      FirstAidStep(
        'Unconscious and not breathing normally: resuscitation.',
      ),
    ],
    cautions: [
      'Even if it improves quickly: always go to hospital. In a '
          'proportion of cases the reaction returns hours later.',
      'An auto-injector may only be used on the person it was '
          'prescribed for — or on the dispatcher’s instruction.',
    ],
    source:
        'European Resuscitation Council (ERC) First Aid Guidelines '
        '2025',
  ),
  FirstAidGuide(
    id: 'asthma',
    group: FirstAidGroup.illness,
    title: 'Asthma attack',
    when: 'Wheezing, laboured breathing and tightness in the chest.',
    steps: [
      FirstAidStep(
        'Sit them comfortably and reassure them.',
        detail:
            'Sitting upright, leaning forward with the arms braced, often '
            'helps.',
      ),
      FirstAidStep(
        'Help them use their own inhaler. Loosen tight clothing.',
      ),
      FirstAidStep(
        'Call 112.',
        detail:
            'If there is no inhaler and the attack lasts several minutes; '
            'if the inhaler does not work within a few minutes; for severe '
            'breathing difficulty; for bluish lips, ears, fingers or toes; '
            'for confusion; or if the breathing becomes slower and less '
            'noisy.',
      ),
      FirstAidStep(
        'No inhaler: keep them calm, sitting upright, fresh air, away from '
        'the trigger.',
      ),
      FirstAidStep(
        'Stay until the attack is over, and help with further doses of '
        'their own prescription.',
      ),
    ],
    cautions: [
      'Only the inhaler prescribed to this person.',
      'Breathing that becomes slower and quieter, or somebody getting '
          'tired, is not an improvement.',
    ],
    source:
        'International first aid, resuscitation and education guidelines '
        '2025 (IFRC), "Asthma attack"',
  ),
  FirstAidGuide(
    id: 'hypoglycaemia',
    group: FirstAidGroup.illness,
    title: 'Low blood sugar',
    when:
        'Known diabetes, with shaking, sweating, confusion or sudden '
        'irritability.',
    steps: [
      FirstAidStep('Sit or lay them down comfortably.'),
      FirstAidStep(
        'Give them their own glucose: 15 to 20 grams.',
        detail:
            'Otherwise a sugary drink that is not a diet one, such as '
            'fruit juice, or sugar — about three teaspoons, or three '
            'jellybeans.',
      ),
      FirstAidStep('No better after 15 minutes: give the same amount again.'),
      FirstAidStep(
        'No better after about 30 minutes, or they become unresponsive: '
        'call 112.',
      ),
    ],
    facts: [
      FirstAidFact('Sugar', '15 to 20 g'),
      FirstAidFact('Repeat after', '15 minutes'),
    ],
    cautions: [
      'Give something to eat or drink only if they are responsive and able '
          'to swallow.',
      'No diet or light drinks. There is no sugar in them.',
    ],
    source:
        'International first aid, resuscitation and education guidelines '
        '2025 (IFRC), "Diabetic emergency (hypoglycemia)"',
  ),
  FirstAidGuide(
    id: 'croup',
    group: FirstAidGroup.illness,
    title: 'Croup',
    when:
        'A child wakes in the night with a barking cough and a whistling '
        'breath in.',
    steps: [
      FirstAidStep(
        'Stay calm and settle the child, usually sitting up.',
        detail:
            'That is not a throwaway line: if you stay calm they become '
            'calmer, and the breathing eases.',
      ),
      FirstAidStep('Take their temperature and treat a fever if there is one.'),
      FirstAidStep(
        'Let them breathe warm, humid air.',
        detail:
            'Sitting by a running shower, or leaning over a bowl of hot '
            'water — not hot enough to scald.',
      ),
      FirstAidStep(
        'Watch breathing and response closely. For a severe or persisting '
        'episode: call 112.',
      ),
    ],
    cautions: [
      'Call 112 at once for severe breathing difficulty: sitting up and '
          'leaning forward, mouth open, neck and shoulder muscles working, '
          'nostrils flaring, a hollow forming at the base of the neck.',
      'Mild can become severe within a few hours. And there is a '
          'croup-like inflammation of the epiglottis that needs urgent '
          'medical care. In any doubt, call.',
    ],
    source:
        'International first aid, resuscitation and education guidelines '
        '2025 (IFRC), "Croup"',
  ),
  FirstAidGuide(
    id: 'faint',
    group: FirstAidGroup.illness,
    title: 'About to faint',
    when: 'Going black, pale, dizzy — still conscious.',
    steps: [
      FirstAidStep('Sit or lie down, somewhere nobody can fall.'),
      FirstAidStep(
        'Have them tense their muscles; that drives blood to the head.',
        detail:
            'Squat down; or cross the legs and tense leg, abdominal and '
            'buttock muscles hard. The lower half works better than the '
            'upper.',
      ),
      FirstAidStep('If they are lying down: raise their legs if they want.'),
      FirstAidStep('Stay, watch, and work out what is behind it.'),
    ],
    cautions: [
      'After a faint, get up and carry on only gradually — otherwise they '
          'go straight down again.',
      'If somebody has fallen, think of the head and of bones.',
      'Somebody who faints comes round very quickly. If they stay '
          'unresponsive it was not a faint: check the breathing.',
    ],
    source:
        'International first aid, resuscitation and education guidelines '
        '2025 (IFRC), "Feeling faint"',
  ),
  FirstAidGuide(
    id: 'fever',
    group: FirstAidGroup.illness,
    title: 'Fever',
    when: 'A raised temperature, shivering, weakness.',
    steps: [
      FirstAidStep('Let them rest and dress lightly.'),
      FirstAidStep('Give them something to drink — sweating costs fluid.'),
      FirstAidStep(
        'Often no medicine is needed.',
        detail:
            'If they feel unwell, paracetamol at the recommended dose can '
            'bring the fever down. Sponging with lukewarm water helps too, '
            'as long as it does not upset them.',
      ),
      FirstAidStep('Watch how they are and look out for new signs.'),
    ],
    cautions: [
      'Do not pack them in clothes and blankets.',
      'Do not sponge with cold water. It is unpleasant and keeps the heat '
          'in the body.',
      'Paracetamol is the one to reach for. Ibuprofen can irritate the '
          'stomach and damage the kidneys. Two antipyretics alongside each '
          'other only with a careful plan, or the dose is doubled.',
    ],
    source:
        'International first aid, resuscitation and education guidelines '
        '2025 (IFRC), "Fever"',
  ),
  FirstAidGuide(
    id: 'childbirth',
    group: FirstAidGroup.illness,
    title: 'Birth with no help coming',
    when:
        'Labour has started and the ambulance or midwife is not there, or '
        'cannot get through.',
    steps: [
      FirstAidStep(
        'Get help — hospital, ambulance, midwife — and let her decide who '
        'she wants with her.',
      ),
      FirstAidStep(
        'First stage: make a safe, quiet, private place.',
        detail: 'She chooses the position: sitting, standing, walking about.',
      ),
      FirstAidStep(
        'Offer warmth and touch if she wants them.',
        detail:
            'Massage the lower back; a warm compress or hot water bottle on '
            'the sacrum, abdomen or perineum can take the edge off the '
            'pain.',
      ),
      FirstAidStep(
        'Second stage: a comfortable position, upright if possible.',
        detail:
            'If she is on her back, a small pillow under the right hip — '
            'otherwise the baby presses on large blood vessels.',
      ),
      FirstAidStep(
        'Wash your hands with soap and water and put a clean cloth '
        'underneath.',
      ),
      FirstAidStep(
        'Support the baby\'s head as it comes.',
        detail:
            'Newborns are slippery. Wipe fluid and mucus away from mouth '
            'and nose.',
      ),
      FirstAidStep(
        'Dry the baby with a clean cloth, wrap it, cover its head and put '
        'it on the mother\'s chest or belly at once.',
        detail: 'Keep the mother just as warm.',
      ),
      FirstAidStep(
        'Third stage: wait for the afterbirth and keep it.',
        detail: 'The professionals will still need it.',
      ),
    ],
    cautions: [
      'From here on there are two patients: the mother and the baby.',
      'Force nothing and pull on nothing. What is written here is '
          'accompanying a birth, not delivering one.',
    ],
    source:
        'International first aid, resuscitation and education guidelines '
        '2025 (IFRC), "Emergency childbirth"',
  ),
  FirstAidGuide(
    id: 'hypothermia',
    group: FirstAidGroup.environment,
    title: 'Hypothermia',
    when:
        'Shivering, cold pale skin, slowing down, confusion — after '
        'cold, wet or wind. When the shivering stops, it is getting '
        'dangerous.',
    steps: [
      FirstAidStep('Get them out of the cold, out of wind and wet.'),
      FirstAidStep('Take off wet clothing, cutting it off if need be.'),
      FirstAidStep(
        'Wrap them in blankets, underneath as well.',
        detail: 'Cover the head too. The ground takes the most heat.',
      ),
      FirstAidStep(
        'Awake and able to swallow: warm, sweet drinks.',
      ),
      FirstAidStep(
        'Warmth on trunk, neck and head, not on arms and legs.',
        detail:
            'A hot water bottle or a heat pad, always with a cloth '
            'in between.',
      ),
      FirstAidStep(
        'Call 112 for confusion, for shivering that has stopped, or for '
        'drowsiness.',
      ),
    ],
    cautions: [
      'Do not rub arms and legs and do not warm them actively. That '
          'drives cold blood to the heart.',
      'Move them as little as possible. A deeply cold heart can stop '
          'from being jolted.',
      'No alcohol. It feels warm and cools them down.',
      'In severe hypothermia check breathing and pulse for up to a '
          'minute — both may be barely detectable. Nobody is dead until '
          'they are warm and dead.',
    ],
    source:
        'European Resuscitation Council (ERC) First Aid Guidelines '
        '2025',
  ),
  FirstAidGuide(
    id: 'heat',
    group: FirstAidGroup.environment,
    title: 'Heat exhaustion and heatstroke',
    when:
        'After heat or exertion: weakness, headache, nausea. If hot '
        'dry skin, confusion or unconsciousness join it, it is '
        'heatstroke and life-threatening.',
    steps: [
      FirstAidStep('Get them into shade or a cool room.'),
      FirstAidStep('Lay them down, legs up, loosen clothing.'),
      FirstAidStep('Conscious: let them sip water.'),
      FirstAidStep(
        'Cool them: damp cloths, fan air over them, cold water on neck, '
        'armpits and groin.',
      ),
      FirstAidStep(
        'Call 112 for confusion, hot dry skin, vomiting or '
        'unconsciousness.',
        detail:
            'That is heatstroke. Keep cooling until the ambulance '
            'arrives.',
      ),
    ],
    cautions: [
      'Give nothing to drink if they are confused or not fully awake.',
      'No alcohol and nothing with caffeine.',
      'Heatstroke is not a bad case of sunburn. Untreated it kills.',
    ],
    source:
        'German Federal Centre for Health Education (BZgA) and ERC '
        'First Aid Guidelines 2025',
  ),
  FirstAidGuide(
    id: 'poisoning',
    group: FirstAidGroup.environment,
    title: 'Poisoning',
    when:
        'Something has been swallowed, breathed in, spilled or got '
        'into the eyes that does not belong there.',
    steps: [
      FirstAidStep(
        'Your own safety: do not walk into gas or smoke.',
      ),
      FirstAidStep(
        'Call a poison centre. For unconsciousness or difficulty '
        'breathing, call 112 first.',
      ),
      FirstAidStep(
        'Have ready what they will ask.',
        detail:
            'What, how much, when, how old and how heavy the person '
            'is, what symptoms.',
      ),
      FirstAidStep(
        'Keep the packaging, what is left, and any vomit.',
      ),
      FirstAidStep(
        'Skin or eyes affected: rinse for 10 to 15 minutes under running '
        'water.',
        detail:
            'For an eye, from the inner corner outwards so nothing '
            'runs into the good eye.',
      ),
      FirstAidStep(
        'Unconscious and breathing normally: recovery position.',
      ),
    ],
    facts: poisonCentres,
    cautions: [
      'Do not make them vomit. With acids, alkalis and foaming agents '
          'the way back up does more harm than the way down.',
      'No milk. It speeds up the uptake of many poisons.',
      'No salt water.',
      'These numbers are a stored snapshot. Check them while you have a '
          'network, and put the one that covers you into your emergency '
          'contacts.',
    ],
    source:
        'German poison information centres, Federal Institute for '
        'Risk Assessment (BfR)',
  ),
  // ---------------------------------------------------------------------
  // Mental distress.
  //
  // These five do not follow the ERC but the IFRC's `International first
  // aid, resuscitation and education guidelines 2025`. The order of the
  // actions is theirs, the words are this app's; the guidelines' copyright
  // page permits non-commercial reproduction with the source named, and
  // named it is, on every one of these screens.
  //
  // What is deliberately absent although it is everywhere: the paper bag
  // and the "five things you can see". The 2025 guidelines explicitly
  // endorse neither ("Anxiety and panic", the Delphi section). What they
  // do recommend is breathing with the person, so that is all that is
  // here.
  FirstAidGuide(
    id: 'frostbite',
    group: FirstAidGroup.environment,
    title: 'Frostbite',
    when: 'White, hard, numb patches on fingers, toes, nose or ears.',
    steps: [
      FirstAidStep(
        'Protect them from hypothermia first.',
        detail:
            'Move them somewhere warmer, take off wet clothing, keep them '
            'dry and warm.',
      ),
      FirstAidStep(
        'Take off jewellery carefully, while that is possible without '
        'damaging the skin.',
      ),
      FirstAidStep(
        'Warm the area gently in water at body temperature.',
        detail: 'Usually about 30 minutes, until it is warmed through.',
      ),
      FirstAidStep(
        'Dress it with sterile gauze. Where several digits are affected, '
        'put gauze between them.',
      ),
      FirstAidStep(
        'The guidelines additionally put a painkiller up for '
        'consideration.',
        detail:
            'A high dose of ibuprofen, 400 to 800 mg, or — where that is '
            'not available — a low dose of acetylsalicylic acid, 75 to '
            '81 mg. It may improve healing. The amounts are the '
            "guidelines', not this app's.",
      ),
    ],
    facts: [FirstAidFact('Rewarming', 'body-temperature water, ~30 minutes')],
    cautions: [
      'Do not rub and do not handle roughly — that damages the skin.',
      'Not near direct heat such as a fan heater or a stove.',
      'Do not break blisters.',
      'Rewarm only where refreezing is ruled out. Frostbite always needs '
          'medical care.',
    ],
    source:
        'International first aid, resuscitation and education guidelines '
        '2025 (IFRC), "Frostbite"',
  ),
  FirstAidGuide(
    id: 'dehydration',
    group: FirstAidGroup.environment,
    title: 'Dehydration',
    when:
        'After diarrhoea, vomiting, fever or heat: thirst, little and dark '
        'urine, weakness.',
    steps: [
      FirstAidStep('Reassure them and give them plenty to drink.'),
      FirstAidStep('Mild case: water is enough.'),
      FirstAidStep(
        'More severe: an oral rehydration solution.',
        detail: 'If there is none: apple juice, coconut water or water.',
      ),
      FirstAidStep(
        'To make it yourself: half a teaspoon of salt and six teaspoons of '
        'sugar in one litre of drinking water.',
      ),
      FirstAidStep(
        'Call 112 if they become confused or stop responding.',
      ),
    ],
    facts: [
      FirstAidFact('Solution per litre', 'half tsp salt, 6 tsp sugar'),
      FirstAidFact('Children 2 to 5 years', '10 ml per kg'),
    ],
    cautions: [
      'Nothing alcoholic.',
      'No rehydration solution during a diabetic high-sugar crisis — it '
          'makes the dehydration worse.',
      'Seek medical advice for babies, children and older people, where '
          'more is being lost than taken in, where there is very little or '
          'very dark urine, with fever or heat exhaustion, and in doubt.',
    ],
    source:
        'International first aid, resuscitation and education guidelines '
        '2025 (IFRC), "Dehydration"',
  ),
  FirstAidGuide(
    id: 'psychological-first-aid',
    group: FirstAidGroup.mentalDistress,
    title: 'Psychological first aid',
    when:
        'Somebody is shaken, frozen or beside themselves after an '
        'incident. This page applies to all the ones that follow.',
    steps: [
      FirstAidStep(
        'Safety first, then everything else.',
        detail:
            'If the place is not safe, this does not start here — not '
            'for you and not for the other person.',
      ),
      FirstAidStep(
        'Look: who needs help, and who needs it most?',
        detail:
            'Injuries first. Whoever sits quietly in the corner is '
            'easily overlooked; loud is not the same as badly off.',
      ),
      FirstAidStep(
        'Approach calmly, give your name, and say that you want to '
        'help.',
        detail: 'At the same height, with no phone in your hand.',
      ),
      FirstAidStep(
        'Listen, and let every reaction stand.',
        detail:
            'Crying, anger, silence, indifference — all of it happens, '
            'and none of it has to be talked away.',
      ),
      FirstAidStep(
        'Ask what is needed rather than guessing.',
        detail:
            'Open questions, and the decision stays with the person. '
            'Deciding for themselves again is what settles people.',
      ),
      FirstAidStep(
        'See to what is nearest: warmth, something to drink, a quiet '
        'place.',
        detail:
            'For a child that means above all finding their caregiver '
            'again.',
      ),
      FirstAidStep(
        'Link: to relatives, to reliable information, to further help.',
        detail:
            'Say what you know and what you do not. Uncertainty '
            'frightens people more than bad news does.',
      ),
    ],
    facts: [
      FirstAidFact('Crisis helpline, around the clock', '0800 111 0 111'),
      FirstAidFact('Crisis helpline, EU-wide', '116 123'),
      FirstAidFact('Out-of-hours medical service', '116 117'),
    ],
    cautions: [
      'Do not ask for details of what happened. Whoever wants to tell '
          'you will tell you — and may stop at any point.',
      'Do not interpret and do not judge. Psychological first aid is not '
          'a conversation about causes and not therapy.',
      'No help against the person\'s will, and no touching without '
          'permission.',
      'Do not leave to fetch help without first finding somebody who '
          'will look after the person.',
    ],
    source:
        'International first aid, resuscitation and education guidelines '
        '2025 (IFRC), "Psychological first aid" (Look – Listen – Link, '
        'after the WHO)',
  ),
  FirstAidGuide(
    id: 'suicidal-ideation',
    group: FirstAidGroup.mentalDistress,
    title: 'Suicidal thoughts',
    when: 'Somebody says or shows that they do not want to live any more.',
    steps: [
      FirstAidStep(
        'Take it seriously. Every mention, including a passing one.',
      ),
      FirstAidStep(
        'Ask directly.',
        detail:
            'Talking about it does not make it more likely that '
            'somebody does it. Asking openly and gently takes away what '
            'is forbidden about the subject.',
      ),
      FirstAidStep(
        'Say from the start that you cannot keep to yourself anything '
        'that is life-threatening.',
        detail:
            'That belongs at the beginning, not at the end — otherwise '
            'it is a breach of trust instead of a condition.',
      ),
      FirstAidStep(
        'Do not leave the person alone.',
        detail: 'On the phone: ask where they are and who they trust.',
      ),
      FirstAidStep(
        'Have them put away anything they could hurt themselves with.',
        detail:
            'Medicines, tools, weapons. Better still if somebody in the '
            'household helps with it.',
      ),
      FirstAidStep(
        'Make the place safe.',
        detail:
            'A quiet room lower down the building, windows shut, away '
            'from anything dangerous.',
      ),
      FirstAidStep(
        'Get help together — call while you are there, do not send them '
        'off with a task.',
        detail:
            'Crisis line, family doctor, community mental health '
            'service, psychiatric hospital.',
      ),
      FirstAidStep(
        'In immediate danger, or after an attempt: 112.',
        detail:
            'After an attempt, physical first aid comes first — '
            'bleeding, poisoning, unconsciousness.',
      ),
    ],
    facts: [
      FirstAidFact('Crisis helpline, around the clock', '0800 111 0 111'),
      FirstAidFact('Crisis helpline, second number', '0800 111 0 222'),
      FirstAidFact('Crisis helpline, EU-wide', '116 123'),
      FirstAidFact('Children and young people', '116 111'),
      FirstAidFact('Emergency number, immediate danger', '112'),
    ],
    cautions: [
      'Do not promise to keep it to yourself. That is a promise nobody '
          'can keep.',
      'Do not judge and do not argue. What helps is listening.',
      'Do not walk away to fetch help. First make sure somebody stays.',
      'This page is no substitute for training. It is meant to make you '
          'aware, not expert.',
    ],
    source:
        'International first aid, resuscitation and education guidelines '
        '2025 (IFRC), "Suicidal ideation"; telephone numbers of '
        'TelefonSeelsorge Deutschland and Nummer gegen Kummer',
  ),
  FirstAidGuide(
    id: 'anxiety-panic',
    group: FirstAidGroup.mentalDistress,
    title: 'Anxiety and panic attack',
    when:
        'Racing heart, breathlessness, a tight chest, the fear of dying '
        '— and after minutes it recedes by itself.',
    steps: [
      FirstAidStep(
        'Introduce yourself and say that you are staying.',
      ),
      FirstAidStep(
        'Move to a quiet place, away from onlookers.',
        detail: 'Loosen tight clothing.',
      ),
      FirstAidStep(
        'Ask whether they have had this before.',
        detail:
            'Somebody who recognises the attack has already lost half '
            'the fear of it.',
      ),
      FirstAidStep(
        'Say that it is a reaction to strain and that it eases by '
        'itself.',
        detail: 'The peak is past after ten to fifteen minutes.',
      ),
      FirstAidStep(
        'Speak slowly and quietly, in short sentences.',
      ),
      FirstAidStep(
        'Breathe in front of them and have them breathe with you.',
        detail:
            'In through the nose for one count, out through the mouth '
            'for three, and let the breath go into the belly.',
      ),
      FirstAidStep(
        'Say there is nothing shameful about it and nobody is going '
        'mad.',
      ),
      FirstAidStep(
        'Stay until it is over.',
        detail:
            'If it happens repeatedly, or somebody arranges their life '
            'around it, advise a doctor: there is effective help.',
      ),
    ],
    facts: [
      FirstAidFact('Peak of the attack', 'after 10 to 15 minutes'),
      FirstAidFact('Breathing', 'in for 1, out for 3'),
      FirstAidFact('Crisis helpline, EU-wide', '116 123'),
    ],
    cautions: [
      'No paper bag over the mouth. The 2025 guidelines endorse neither '
          'that nor similar home remedies; what they recommend is '
          'breathing with the person.',
      'Not "calm down" and not "there is nothing there". The fear is '
          'real even when the danger is not.',
      'If in doubt whether it is a panic attack or an emergency: 112. '
          'Chest pain and breathlessness can come from the heart.',
    ],
    source:
        'International first aid, resuscitation and education guidelines '
        '2025 (IFRC), "Anxiety and panic"',
  ),
  FirstAidGuide(
    id: 'traumatic-event',
    group: FirstAidGroup.mentalDistress,
    title: 'After a traumatic event',
    when:
        'Shortly after an accident, a disaster or violence — for those '
        'affected and for helpers.',
    steps: [
      FirstAidStep(
        'The physical first: stop the bleeding, treat, resuscitate.',
        detail: 'Stay calm and present while you do. Both happen at once.',
      ),
      FirstAidStep(
        'Say what you are doing, in short and simple sentences.',
      ),
      FirstAidStep(
        'Stay, listen, and let the feelings stand.',
      ),
      FirstAidStep(
        'Let the person share in the decisions about their care.',
        detail:
            'Being asked and allowed to choose hands back a piece of '
            'control.',
      ),
      FirstAidStep(
        'Bring in relatives or friends where you can.',
      ),
      FirstAidStep(
        'Tell the ambulance crew how the person is, physically and '
        'emotionally.',
      ),
    ],
    facts: [
      FirstAidFact('Out-of-hours medical service', '116 117'),
      FirstAidFact('Crisis helpline, EU-wide', '116 123'),
    ],
    cautions: [
      'Do not press them to talk and do not ask for details.',
      'Strong reactions in the first days are ordinary and not yet an '
          'illness.',
      'They can also arrive weeks or months later. If they persist or '
          'worsen, that belongs in a doctor\'s hands.',
    ],
    source:
        'International first aid, resuscitation and education guidelines '
        '2025 (IFRC), "Traumatic event"',
  ),
  FirstAidGuide(
    id: 'acute-grief',
    group: FirstAidGroup.mentalDistress,
    title: 'Acute grief',
    when: 'Somebody has just learned that a person has died.',
    steps: [
      FirstAidStep(
        'Introduce yourself and say you are there, if the person does '
        'not know you.',
      ),
      FirstAidStep(
        'Move somewhere safe and make room.',
        detail: 'Nobody should feel crowded.',
      ),
      FirstAidStep(
        'Ask directly what you can help with.',
      ),
      FirstAidStep(
        'Be fully there and let every reaction stand.',
        detail:
            'Shock, anger, guilt, indifference — after a sudden death '
            'all of that is ordinary.',
      ),
      FirstAidStep(
        'Ask whether they would like to see the person who died, where '
        'that is possible.',
        detail:
            'Say beforehand how they will look. Time with the body '
            'eases grieving and takes away guilt.',
      ),
      FirstAidStep(
        'Help them reach relatives rather than being left alone.',
      ),
      FirstAidStep(
        'Encourage breaks — something to do that takes the mind '
        'elsewhere for a while.',
      ),
    ],
    facts: [
      FirstAidFact('Crisis helpline, around the clock', '0800 111 0 111'),
      FirstAidFact('Crisis helpline, EU-wide', '116 123'),
    ],
    cautions: [
      'Do not leave without having satisfied yourself that they are all '
          'right.',
      'No comparisons and no deadlines. Grief has no duration after '
          'which it is meant to be over.',
      'Do not tell the person what they ought to be feeling.',
    ],
    source:
        'International first aid, resuscitation and education guidelines '
        '2025 (IFRC), "Acute grief"',
  ),
];
