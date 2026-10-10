<!--
The first aid guides in English.

Same ids, same order and the same number of steps as
`first_aid_guides_de.dart` — `first_aid_guides_test.dart` holds the two
files to that. A translation that quietly drops a step would be a
translation that quietly drops a step of a resuscitation.

The telephone numbers are the German ones, because the app is used in
Germany whatever language it is read in. 112 is the emergency number
across the European Union either way.

Format: README.md in this folder.
-->

## emergency-call
- group: basics
- title: Making the call
- when: First of all, as soon as somebody is in serious trouble.
- source: German Federal Office of Civil Protection and Disaster Assistance (BBK)

### steps
1. Where did it happen?
   Town, street, number, floor. In the countryside: the village and what stands nearby.
2. What happened?
   One sentence is enough: fell off a roof, not breathing, car into a tree.
3. How many people are hurt?
4. What kind of injuries?
   What you can see, not what you suspect.
5. Wait for questions.
   The dispatcher ends the call, not you. They will talk you through what to do until the ambulance arrives.

### cautions
- Do not hang up until the dispatcher says so.
- No signal does not mean no emergency call: 112 works without credit and, in many cases, over another network.

### facts
- Ambulance and fire brigade: 112
- Police: 110
- Out-of-hours doctor: 116 117
- Across Europe: 112

## unresponsive
- group: basics
- title: Checking an unresponsive person
- when: Somebody is lying there and does not react. This is where everything else starts.
- source: European Resuscitation Council (ERC) Guidelines 2025

### steps
1. Your own safety first.
   Traffic, electricity, smoke, gas. A second casualty helps nobody.
2. Speak loudly and shake the shoulders.
3. No response? Shout for help and call 112.
   Put the phone on speaker so your hands stay free.
4. Open the airway.
   One hand on the forehead, two fingers of the other under the chin, tilt the head gently back.
5. Look for breathing for no longer than 10 seconds.
   Is the chest rising? Can you hear breath? Can you feel air on your cheek?
6. Breathing normally: recovery position, and keep watching.
7. Not breathing normally: start resuscitation at once.

### cautions
- Occasional gasps are not normal breathing. This agonal breathing is common in the first minutes of a cardiac arrest and is regularly mistaken for breathing — in doubt, treat it as no breathing.
- When in doubt, push. Chest compressions on somebody whose heart is still beating do far less harm than no resuscitation on somebody whose heart has stopped.

## cpr-adult
- group: lifeThreatening
- title: Resuscitation — adult
- when: The person does not react and is not breathing normally.
- callFirst: true
- drawing: compressionPoint
- pacer: true
- source: European Resuscitation Council (ERC) Guidelines 2025

### steps
1. Call 112 and send someone for a defibrillator.
   Alone: call first, speaker on, then push. With someone else: they call and fetch the AED, you push.
2. Start where the person is lying.
   Open clothing only if you cannot find the pressure point otherwise. Move them onto a firm surface only if it takes seconds — any delay costs more than the soft surface.
3. Heel of one hand on the centre of the chest, the other hand on top, fingers interlocked.
   Centre of the chest means the lower half of the breastbone.
4. Push 30 times.
   5 to 6 cm deep, 100 to 120 times a minute, arms straight, vertically from above. Let the chest come all the way back up after each push.
5. Give 2 rescue breaths.
   Head tilted back, nose pinched, blow steadily for one second until the chest visibly rises. No more than 10 seconds for both.
6. Carry on 30:2 without a break.
   Until the ambulance takes over, an AED tells you to stand clear, or the person starts breathing normally.
7. With two of you, swap every two minutes.
   The swap takes seconds. Tired hands push too shallow without anyone noticing.

### cautions
- If you cannot or will not give breaths, keep pushing without stopping. Compression-only is markedly better than nothing.
- Do not stop to check whether it is working. Every interruption lets the pressure in the circulation collapse.
- Cracking sounds are normal and are not a reason to stop.

### facts
- Rate: 100–120 per minute
- Depth: 5–6 cm
- Ratio: 30 compressions : 2 breaths

## cpr-child
- group: lifeThreatening
- title: Resuscitation — child and infant
- when: A pre-pubescent child or an infant does not react and is not breathing normally.
- callFirst: true
- pacer: true
- source: European Resuscitation Council (ERC) Guidelines 2025

### steps
1. Call 112 as soon as the child does not react and is not breathing normally.
   Speaker on, phone down — you stay with the child and keep your hands free. Until 2021 the rule here was one minute of resuscitation first; since the 2025 guidelines the order is the same as for an adult.
2. Start with 5 rescue breaths, not with compressions.
   In children the heart nearly always stops for want of oxygen, not the other way round. On an infant, seal your mouth over mouth and nose together.
3. Push 15 times, then give 2 breaths.
   Child: one or two heels of the hand. Infant: two fingers, or both thumbs with your hands encircling the chest.
4. Push a third of the depth of the chest.
   About 5 cm in a child, about 4 cm in an infant. Same rate as an adult: 100 to 120 a minute.
5. Carry on 15:2 until help arrives.

### cautions
- If 15:2 is more than you trust yourself with, use 30:2 as for an adult. That is expressly allowed and far better than hesitating.
- Pushing too gently is the commonest mistake. A child whose heart has stopped cannot be saved by timid compressions.

### facts
- First: 5 rescue breaths
- Then: 15 compressions : 2 breaths
- Depth, child: about 5 cm
- Depth, infant: about 4 cm
- Rate: 100–120 per minute

## aed
- group: lifeThreatening
- title: Defibrillator (AED)
- when: A device is within reach while resuscitation is under way.
- source: European Resuscitation Council (ERC) Guidelines 2025

### steps
1. Switch it on. From now on it talks you through it.
2. Keep pushing while the pads go on.
   Only break off if you are on your own.
3. Stick the pads on the bare chest as printed on them.
   One below the right collarbone, one on the left side below the armpit. Chest wet? Dry it first.
4. Touch nobody while it analyses.
5. Shock advised: make sure nobody is touching the person, then press.
6. Go straight back to compressions.
   Without waiting for a reaction. The device speaks up again after two minutes by itself.

### cautions
- An AED never shocks somebody who does not need it. It analyses by itself and only then releases the button.
- Children under eight: use paediatric pads if there are any. If there are none, use the adult pads — better than no shock.
- Do not put a pad over a pacemaker; a few centimetres to the side is enough. Peel off any medication patches first.

## recovery-position
- group: lifeThreatening
- title: Recovery position
- when: The person is unconscious and breathing normally.
- drawing: recoveryPosition
- source: European Resuscitation Council (ERC) Guidelines 2025

### steps
1. Kneel beside them and straighten their legs.
2. Place the near arm at a right angle, palm upwards.
3. Bring the far arm across the chest, hold the back of that hand against the near cheek and keep it there.
4. Bend the far knee up and pull them towards you by that knee.
5. Arrange the upper leg so hip and knee are both at right angles.
6. Tilt the head back so the airway stays open and the mouth is the lowest point.
7. Keep watching the breathing.
   If it stops or turns abnormal: roll them onto their back and start resuscitation.

### cautions
- Turn them onto the other side after 30 minutes at the latest.
- With a suspected spinal injury, only turn them if the airway cannot be kept open any other way. The airway comes first.

## choking
- group: lifeThreatening
- title: Choking
- when: Somebody clutches their throat, cannot speak, cannot cough, cannot breathe.
- drawing: choking
- source: European Resuscitation Council (ERC) Guidelines 2025

### steps
1. Still coughing hard: tell them to keep coughing and stay with them.
   A cough is stronger than anything you can do.
2. The cough weakens: 5 blows between the shoulder blades.
   Lean them forward, strike firmly with the heel of your hand, check after each one.
3. Still stuck: 5 abdominal thrusts.
   From behind, a fist between navel and the bottom of the breastbone, grasp it with the other hand, pull sharply in and up.
4. Carry on alternating: 5 blows, 5 thrusts.
5. If they become unconscious: 112 and start resuscitation.

### cautions
- No abdominal thrusts on an infant under one year. Instead 5 back blows face-down along your forearm, then 5 chest thrusts face-up.
- Do not sweep blindly in the mouth with your fingers. That usually pushes the object deeper.
- After abdominal thrusts always have them checked by a doctor, even if all seems well — internal injuries are possible.

### facts
- Alternate: 5 back blows, 5 abdominal thrusts
- Infant: 5 back blows, 5 chest thrusts

## drowning
- group: lifeThreatening
- title: Drowning
- when: Somebody is in trouble in the water, or has just been got out.
- source: International first aid, resuscitation and education guidelines 2025 (IFRC), "Drowning"

### steps
1. Do not go into the water.
   Somebody actively drowning holds on and pulls the helper under. Help from the bank or from a boat.
2. Reach out with something rigid, or throw something that floats.
   A pole, a branch, an oar, a rope, a ring buoy.
3. Call 112.
4. On land, speak to them loudly and check the breathing.
5. Not breathing normally: resuscitate at once, 30 compressions and 2 rescue breaths.
   With drowning the rescue breaths belong to it — unlike a cardiac arrest. Start with the compressions all the same.
6. Defibrillator: dry the skin before the pads go on.
7. Breathing normally: recovery position, head placed so that fluid can drain from the mouth.
8. Take vomit or debris out only where it is genuinely blocking the breathing.

### cautions
- No resuscitation in the water. That is for rescuers specifically and repeatedly trained for it, not for a bystander.
- Do not take hold of somebody who is actively drowning.
- No pressure on the chest that makes breathing harder.

### facts
- Ratio: 30 compressions, 2 breaths

## severe-bleeding
- group: injury
- title: Severe bleeding
- when: Blood is flowing hard, spurting, or soaking through clothing.
- callFirst: true
- drawing: bleeding
- source: European Resuscitation Council (ERC) First Aid Guidelines 2025

### steps
1. Press directly on the wound, at once.
   With your hand, with a cloth, with whatever is there. Gloves only if they are within reach.
2. Call 112, or have someone call.
3. Raise the bleeding part if you can.
4. Put on a pressure dressing and keep the pressure on.
   Bleeding through: do not take it off, add another layer over it and keep pressing.
5. If bleeding from an arm or leg cannot be stopped that way: tourniquet.
   5 to 7 cm above the wound, never over a joint. Tight enough that the bleeding stops. Write the time on the skin.
6. Lay them flat and keep them warm.
   Watch for signs of shock.

### cautions
- A tourniquet once applied stays on until medical staff remove it. Loosening and retightening is more dangerous than leaving it.
- Do not lift the dressing to look. Every look tears open the clotting that has just formed.
- Do not pull out an embedded object. It is plugging the wound it made. Pad around it instead.

## shock
- group: injury
- title: Shock
- when: Pale, cold clammy skin, fast shallow pulse, restless or strikingly apathetic — after blood loss, burns or severe pain.
- callFirst: true
- source: European Resuscitation Council (ERC) First Aid Guidelines 2025

### steps
1. Call 112.
2. Deal with the cause as far as you can.
   Stop the bleeding first. Without that, positioning does little.
3. Lay them flat and raise the legs about 30 cm.
   Not with a suspected spine, pelvis or leg injury, and not if they are struggling to breathe.
4. Keep them warm.
   A blanket under them as well as over them. The ground takes more heat than the air.
5. Stay, talk to them, watch the breathing.

### cautions
- Nothing to eat and nothing to drink, however firmly they ask. Surgery may be ahead.
- If they lose consciousness and breathe normally: recovery position. If they do not breathe normally: resuscitation.

## amputation
- group: injury
- title: Severed body part
- when: A finger, a hand, a foot is off, wholly or partly.
- source: International first aid, resuscitation and education guidelines 2025 (IFRC), "Amputation"

### steps
1. Call 112.
2. If it is bleeding heavily: stop the bleeding first as for severe bleeding, and treat the person for shock.
3. Partly severed: keep the limb as still as possible, preferably in normal alignment, and cover it with a sterile dressing or clean cloth.
4. Completely severed: cover the wound with a sterile dressing or clean cloth.
5. Keep the severed part dry and cool.
   Into a clean, watertight bag, sealed firmly, and that bag into a larger container of ice and water. Send it with the person to the hospital.
6. Stay with the person and think of them, not only of the wound.
   Psychological first aid applies here to the injured, to their family — and to you.

### cautions
- Not straight into water and not straight onto ice. That damages the tissue and can make reattachment impossible.
- This is a large open wound. Mind your own protection.

## chest-abdomen-injury
- group: injury
- title: Chest or abdomen injury
- when: A stab, a gunshot, an impalement or blunt force to the trunk.
- source: International first aid, resuscitation and education guidelines 2025 (IFRC), "Chest and abdomen injuries"

### steps
1. Abdomen: lying flat with the knees drawn up.
   That takes the tension out of the abdominal wall.
2. Chest: sitting, leaning slightly towards the injured side.
   That is how the good lung works best.
3. Control bleeding with pressure.
4. Call 112.
5. Cover an abdominal wound with a clean dressing once the bleeding is controlled.
   If organs are bulging out, do not push them back — cover them with a clean, wet dressing.
6. Reassure them and watch breathing, circulation and response, particularly for signs of shock.

### cautions
- Do not seal an open chest wound airtight. Air then builds up inside the chest.
- When pressing on a chest wound, do not close the wound completely.

## burns
- group: injury
- title: Burns and scalds
- when: Heat, fire, hot liquid, electricity or chemicals have injured the skin.
- source: European Resuscitation Council (ERC) First Aid Guidelines 2025

### steps
1. Stop the cause.
   Smother flames, switch off the power, take off hot soaked clothing as long as it is not stuck.
2. Cool small areas for 10 to 20 minutes.
   Running lukewarm water, around 20 °C. Hands, feet, face or single patches only.
3. Take off rings, watches and bracelets straight away.
   Before it swells. Afterwards it is too late.
4. Cover loosely with something clean.
   A burn dressing or a clean cloth. Nothing that sheds fibres.
5. Do not cool large areas — cover them and keep the person warm.
   More than the casualty’s own palm. Cooling then causes hypothermia, which is more dangerous than the burn.
6. Call 112 for large areas, for face, hands, genitals or joints, for children, and for electrical and chemical burns.

### cautions
- No ice, no iced water. That does further damage.
- Do not open blisters.
- No ointment, no oil, no flour, no powder, no home remedy.
- Do not pull off clothing that has stuck. Cut around it rather than tearing it away.

## fracture
- group: injury
- title: Fracture, sprain, strain
- when: After a fall or a blow: pain, swelling, a limb out of shape.
- source: International first aid, resuscitation and education guidelines 2025 (IFRC), "Fractures, sprains and strains"

### steps
1. Keep the injured part still.
2. Support it in a comfortable position so nothing moves.
   Keeping it raised can reduce the swelling.
3. Cool it for up to 20 minutes.
   Longer damages the skin. As soon after the injury as you can, and always wrap the cold pack in a cloth.
4. Call 112 for a lot of pain, a lot of swelling, signs of shock, a fracture of the thigh bone, or a limb in an abnormal position.
5. Open fracture: stop the bleeding first, then stabilize the limb.

### cautions
- Never put a cold pack straight onto the skin.
- Stop cooling if it becomes too painful. If the pain returns and the skin is back to its normal temperature, you may cool again.
- Fractures and dislocations always belong in medical hands. In doubt whether it is a fracture, a sprain or a strain: see a doctor.

### facts
- Cooling: 20 minutes at most

## spinal-injury
- group: injury
- title: Suspected spinal injury
- when: A fall from height, a dive, a road collision — and pain in the neck or back.
- source: International first aid, resuscitation and education guidelines 2025 (IFRC), "Spinal injury"

### steps
1. Do not move them. They stay as you found them.
2. If they are responsive: reassure them and ask them to stay as still as they can.
3. For a child, for somebody drowsy, or where somebody cannot follow: support the head gently.
   So that neck and spine do not move.
4. Call 112.
5. Unresponsive and breathing normally: leave them, open the airway and support the head in that position.
6. Keep them warm and watch breathing and response until the ambulance arrives.

### cautions
- Do not reposition them while the breathing is normal and there is no danger.
- If they must be moved after all, for danger: at least two helpers, one keeping the head in line with the spine.
- With a suspected pelvic fracture, do not rock or rotate the pelvis — that can restart bleeding.

### facts
- If they must be moved: at least two helpers

## head-injury
- group: injury
- title: Head injury and concussion
- when: A blow to the head, or a fall onto it.
- source: International first aid, resuscitation and education guidelines 2025 (IFRC), "Head injury and concussion"

### steps
1. Take them out of the activity and have them rest.
2. Watch for the signs of concussion, and for any change in response and breathing.
3. Severe head injury: call 112, reassure them, keep head and neck as still as possible.
   If they are lying down you can hold the head still with your hands or knees.
4. Watch response and breathing until the ambulance arrives.

### cautions
- Not every knock on the head is a concussion. Where the signs are absent or mild, rest helps — they still have to be watched.
- A concussion can develop over hours or days.
- Back to work, the wheel, machinery or sport only once the signs have gone.

## cuts-and-grazes
- group: injury
- title: Cuts and grazes
- when: The small injury there is most of.
- source: International first aid, resuscitation and education guidelines 2025 (IFRC), "Cuts and grazes"

### steps
1. If it is bleeding heavily: pressure on the wound first, then on from here.
2. Rinse with clean drinking water, lukewarm and from a tap if you can.
   No tap: pierce a clean, unused water bottle — that gives a gentle stream.
3. Take out what dirt is left with water and a clean compress.
4. Dry the skin around it and cover the wound.
   A dressing, film, hydrocolloid — or simply a plaster.

### cautions
- If tetanus cover is uncertain, see a doctor. After a dirty wound a booster counts every five years, otherwise every ten.
- Change the dressing only when it is visibly soaked through. While it is clean, it stays on.

### facts
- Tetanus after a dirty wound: every 5 years

## nosebleed
- group: injury
- title: Nosebleed
- when: Blood from the nose, by itself or after a knock.
- source: International first aid, resuscitation and education guidelines 2025 (IFRC), "Nosebleeds"

### steps
1. Sit down and tip the head slightly forward.
   Forward, not back.
2. Pinch the nostrils together, 10 to 15 minutes without letting go.
3. If it has not stopped after 15 minutes, or they go lightheaded from the blood loss: medical help.
4. After a blow, with signs of a brain injury, a misshapen nose, a facial fracture — or if they take anticoagulants: call 112 at once.

### cautions
- Do not tip the head back. The blood then runs down the throat.
- See a doctor if they come often in a short time — or if a child under two has had one.

### facts
- Pinching: 10 to 15 minutes without letting go

## animal-bite
- group: injury
- title: Animal bite
- when: Bitten by a dog, a cat or a wild animal.
- source: International first aid, resuscitation and education guidelines 2025 (IFRC), "Mammal bites"

### steps
1. If it is bleeding: pressure on the wound first.
2. Then as for a wound: rinse it and cover it.
3. See a doctor if the wound needs closing or tetanus cover is missing.
4. From a wild animal, without rabies cover: seek medical care.

### cautions
- Animal bites can pass on disease. Even a small bite is not an ordinary small wound.
- Watch for infection: if it becomes warm or more painful, see a doctor.

## tick
- group: injury
- title: Tick bite
- when: A tick is sitting in the skin.
- source: International first aid, resuscitation and education guidelines 2025 (IFRC), "Insect bites or stings"

### steps
1. Get it out as quickly as you can.
   With a tick card or tool, following its instructions. Otherwise grip it with tweezers as close to the skin as possible and pull it out steadily and firmly.
2. Wash the site with soap and water.
3. Write down the date and where it happened, and keep an eye on the spot.
4. See a doctor for fever, unexplained tiredness, joint pain, or if a rash appears.
   The Lyme rash is a patch with a ring around it. It does not always appear.

### cautions
- Do not squeeze the tick's body. That pushes the organisms into the skin.
- No chemicals and no heat to stun or kill it.
- A tick bite is treated differently from a snakebite.

## insect-bite
- group: injury
- title: Insect sting
- when: Bee, wasp, hornet, mosquito.
- source: International first aid, resuscitation and education guidelines 2025 (IFRC), "Insect bites or stings"

### steps
1. Reassure them and keep them from scratching.
2. If the stinger is still in: out as fast as possible.
   Scrape it off with something flat — a bank card, the blunt side of a knife.
3. Clean the site thoroughly with water.
4. Cool it, against swelling, itching and pain.
   If it is on the hand: take the rings off.
5. Call 112 at once for a sting in the mouth or throat, or at any sign of an allergic reaction.
   In the mouth the swelling can close the airway. While you wait, let them suck an ice cube.

### cautions
- Do not take the stinger with tweezers or fingers. That squeezes the venom sac.
- No scratching.
- Breathlessness, a swelling face or circulatory trouble make it anaphylaxis — see its own guide.

## snakebite
- group: injury
- title: Snakebite
- when: In Germany the adder — or a snake somebody keeps.
- source: International first aid, resuscitation and education guidelines 2025 (IFRC), "Snakebites"

### steps
1. Away from the snake, somewhere safe.
2. Have them lie down comfortably and move as little as possible.
3. Call 112.
4. Take off jewellery, watch and tight clothing before it swells.
   Moving the limb as little as you can while you do.
5. Mark the bite and note the time.
6. Watch response and breathing, talk to them calmly and stay.

### cautions
- None of this helps and all of it can harm: a tourniquet, sucking the venom out, a cold compress, rubbing the bite, cutting it open.
- Snakes are traded and travel. It may be a species that does not belong here.

## jellyfish
- group: injury
- title: Jellyfish sting
- when: Burning weals after swimming in the sea.
- source: International first aid, resuscitation and education guidelines 2025 (IFRC), "Aquatic animal injuries"

### steps
1. Take the stinging cells off the skin, protecting yourself as you do.
2. Rinse the area with seawater.
3. Heat on the area, 20 to 30 minutes.
   Warm water or a heat pack, 45 °C at most. Hot enough against the pain, not so hot that it burns.
4. See a doctor where there is a tetanus risk or the pain stays.

### cautions
- Do not rinse with fresh water — seawater.
- For a severe allergic reaction, call 112 at once.

### facts
- Heat: 45 °C at most, 20 to 30 minutes

## blisters
- group: injury
- title: Blisters on the feet
- when: After a long walk — and so the injury that ends an evacuation on foot.
- source: International first aid, resuscitation and education guidelines 2025 (IFRC), "Friction blisters"

### steps
1. Wash the blister and the skin around it with clean water and pat it dry gently.
2. If the blister is intact: cover it with a blister pad.
3. If it has drained by itself: clean the wound and cover it with a sterile dressing.
   If they have to keep walking, a second layer of padding on top helps.

### cautions
- See a doctor if it becomes an open wound or shows infection — hot, increasingly painful, fever.
- With diabetes or a weakened immune system, see a doctor sooner: such wounds infect more easily and heal worse.

## dental-avulsion
- group: injury
- title: Knocked-out tooth
- when: An adult tooth has come out whole.
- source: International first aid, resuscitation and education guidelines 2025 (IFRC), "Dental avulsion"

### steps
1. Stop the bleeding in the mouth with a compress of gauze or clean cotton.
2. Find the tooth and pick it up by the crown only, not the root.
3. Keep it moist.
   Saline, a rehydration solution or clingfilm — with clingfilm, add enough of their saliva so the tooth does not dry out. Otherwise milk or their own saliva.
4. To a dentist or emergency department as fast as possible, taking the tooth.

### cautions
- Do not carry the tooth in the mouth unless the person is an adult, fully awake and can do it safely. A clear airway comes before everything.
- A knocked-out tooth can point to another injury — to the head, for instance. That comes first.

## flash-eye
- group: injury
- title: Flash eye
- when: Hours after welding, a sunbed, snow or the sea: pain, as though there were sand in the eye.
- source: International first aid, resuscitation and education guidelines 2025 (IFRC), "Flash eye"

### steps
1. Away from the light source, and reassure them.
2. Have them take contact lenses out.
3. Spare the eyes: stay indoors, sunglasses, eyes closed as much as possible.
   A cool, damp cloth over the closed lids. Saline or eye drops keep them moist.
4. If it is no better in 24 hours, or gets worse: see a doctor.

### cautions
- No rubbing.
- This is not only a snow thing — it happens by water, on a beach and at a welding bench.

## stroke
- group: illness
- title: Stroke
- when: Sudden: a drooping mouth, a weak arm, slurred speech, disturbed vision, or the worst headache out of nowhere.
- callFirst: true
- drawing: face
- source: European Resuscitation Council (ERC) First Aid Guidelines 2025

### steps
1. Ask them to smile.
   Does one side droop?
2. Ask them to raise both arms in front, palms up.
   Does one drift down or rotate?
3. Ask them to repeat a simple sentence.
   Is it slurred, or are words swapped around?
4. Any one of them wrong: call 112 now.
   And say you think it is a stroke.
5. Note the time it started.
   That is the most important thing you can tell them — it decides the treatment. If they woke up like this, the time is when they were last seen well.
6. Sit them up slightly if they are conscious.

### cautions
- Nothing to eat and nothing to drink. Swallowing can be impaired without it being visible.
- Do not wait to see whether it gets better. Even if the signs go away again it is an emergency.
- Do not drive them, and do not let them drive.

### facts
- F — Face: the face droops
- A — Arms: an arm drifts down
- S — Speech: speech is slurred
- T — Time: call 112 now, note the time

## heart-attack
- group: illness
- title: Heart attack
- when: Pressure, tightness or pain in the chest for more than a few minutes — often with breathlessness, nausea, cold sweat and fear.
- callFirst: true
- source: European Resuscitation Council (ERC) First Aid Guidelines 2025

### steps
1. Call 112 now. Do not wait it out.
2. Sit them up, half upright.
3. Loosen tight clothing, open a window.
4. Stay with them and talk calmly.
   Fear drives the pulse, and with it the heart’s demand for oxygen.
5. Avoid every exertion.
   Do not let them walk, do not let them climb stairs.
6. Unconscious and not breathing normally: start resuscitation.

### cautions
- In women, older people and diabetics the typical chest pain is often missing. Breathlessness, nausea, upper abdominal pain or sudden exhaustion come to the fore instead.
- Do not drive to hospital yourselves. Treatment starts in the ambulance; it does not start in your car.
- Give no medication that was not prescribed for this person.

## seizure
- group: illness
- title: Seizure
- when: Somebody falls, goes stiff and jerks, often with the eyes rolled back and saliva at the mouth.
- source: European Resuscitation Council (ERC) First Aid Guidelines 2025

### steps
1. Make room and move dangerous things away.
2. Put something soft under the head.
3. Look at the clock.
   How long it lasts is the first thing you will be asked.
4. Wait for it to pass.
   Most seizures stop by themselves after a minute or two.
5. Afterwards: recovery position, and stay.
   The confusion afterwards often lasts longer than the seizure did.

### cautions
- Put nothing in the mouth. Nothing. The tongue cannot be swallowed; broken teeth and broken fingers can happen.
- Do not hold them down and do not try to stop the jerking.
- Nothing to drink until they are properly clear again.

### facts
- Call 112 if: it lasts longer than 5 minutes
- Also if: it is a first seizure
- Also if: a second follows without them coming round in between
- Also for: injury, pregnancy, water

## anaphylaxis
- group: illness
- title: Anaphylaxis
- when: After a sting, a nut, a drug or a food: weals, a swelling face, wheezing, a tight throat, a collapsing circulation.
- callFirst: true
- source: European Resuscitation Council (ERC) First Aid Guidelines 2025

### steps
1. Call 112 now and say it is an allergic reaction.
2. Ask for their emergency kit, or look for it.
   Anyone who knows about it usually carries an auto-injector.
3. Press the auto-injector into the outer thigh.
   Through clothing is fine. The instructions are on the device and take seconds to read.
4. Lay them flat, legs up.
   If they are struggling to breathe, let them sit upright instead. Do not let them stand up suddenly.
5. No better after 5 to 15 minutes: a second dose, if there is a second one.
6. Unconscious and not breathing normally: resuscitation.

### cautions
- Even if it improves quickly: always go to hospital. In a proportion of cases the reaction returns hours later.
- An auto-injector may only be used on the person it was prescribed for — or on the dispatcher’s instruction.

## asthma
- group: illness
- title: Asthma attack
- when: Wheezing, laboured breathing and tightness in the chest.
- source: International first aid, resuscitation and education guidelines 2025 (IFRC), "Asthma attack"

### steps
1. Sit them comfortably and reassure them.
   Sitting upright, leaning forward with the arms braced, often helps.
2. Help them use their own inhaler. Loosen tight clothing.
3. Call 112.
   If there is no inhaler and the attack lasts several minutes; if the inhaler does not work within a few minutes; for severe breathing difficulty; for bluish lips, ears, fingers or toes; for confusion; or if the breathing becomes slower and less noisy.
4. No inhaler: keep them calm, sitting upright, fresh air, away from the trigger.
5. Stay until the attack is over, and help with further doses of their own prescription.

### cautions
- Only the inhaler prescribed to this person.
- Breathing that becomes slower and quieter, or somebody getting tired, is not an improvement.

## hypoglycaemia
- group: illness
- title: Low blood sugar
- when: Known diabetes, with shaking, sweating, confusion or sudden irritability.
- source: International first aid, resuscitation and education guidelines 2025 (IFRC), "Diabetic emergency (hypoglycemia)"

### steps
1. Sit or lay them down comfortably.
2. Give them their own glucose: 15 to 20 grams.
   Otherwise a sugary drink that is not a diet one, such as fruit juice, or sugar — about three teaspoons, or three jellybeans.
3. No better after 15 minutes: give the same amount again.
4. No better after about 30 minutes, or they become unresponsive: call 112.

### cautions
- Give something to eat or drink only if they are responsive and able to swallow.
- No diet or light drinks. There is no sugar in them.

### facts
- Sugar: 15 to 20 g
- Repeat after: 15 minutes

## croup
- group: illness
- title: Croup
- when: A child wakes in the night with a barking cough and a whistling breath in.
- source: International first aid, resuscitation and education guidelines 2025 (IFRC), "Croup"

### steps
1. Stay calm and settle the child, usually sitting up.
   That is not a throwaway line: if you stay calm they become calmer, and the breathing eases.
2. Take their temperature and treat a fever if there is one.
3. Let them breathe warm, humid air.
   Sitting by a running shower, or leaning over a bowl of hot water — not hot enough to scald.
4. Watch breathing and response closely. For a severe or persisting episode: call 112.

### cautions
- Call 112 at once for severe breathing difficulty: sitting up and leaning forward, mouth open, neck and shoulder muscles working, nostrils flaring, a hollow forming at the base of the neck.
- Mild can become severe within a few hours. And there is a croup-like inflammation of the epiglottis that needs urgent medical care. In any doubt, call.

## faint
- group: illness
- title: About to faint
- when: Going black, pale, dizzy — still conscious.
- source: International first aid, resuscitation and education guidelines 2025 (IFRC), "Feeling faint"

### steps
1. Sit or lie down, somewhere nobody can fall.
2. Have them tense their muscles; that drives blood to the head.
   Squat down; or cross the legs and tense leg, abdominal and buttock muscles hard. The lower half works better than the upper.
3. If they are lying down: raise their legs if they want.
4. Stay, watch, and work out what is behind it.

### cautions
- After a faint, get up and carry on only gradually — otherwise they go straight down again.
- If somebody has fallen, think of the head and of bones.
- Somebody who faints comes round very quickly. If they stay unresponsive it was not a faint: check the breathing.

## fever
- group: illness
- title: Fever
- when: A raised temperature, shivering, weakness.
- source: International first aid, resuscitation and education guidelines 2025 (IFRC), "Fever"

### steps
1. Let them rest and dress lightly.
2. Give them something to drink — sweating costs fluid.
3. Often no medicine is needed.
   If they feel unwell, paracetamol at the recommended dose can bring the fever down. Sponging with lukewarm water helps too, as long as it does not upset them.
4. Watch how they are and look out for new signs.

### cautions
- Do not pack them in clothes and blankets.
- Do not sponge with cold water. It is unpleasant and keeps the heat in the body.
- Paracetamol is the one to reach for. Ibuprofen can irritate the stomach and damage the kidneys. Two antipyretics alongside each other only with a careful plan, or the dose is doubled.

## childbirth
- group: illness
- title: Birth with no help coming
- when: Labour has started and the ambulance or midwife is not there, or cannot get through.
- source: International first aid, resuscitation and education guidelines 2025 (IFRC), "Emergency childbirth"

### steps
1. Get help — hospital, ambulance, midwife — and let her decide who she wants with her.
2. First stage: make a safe, quiet, private place.
   She chooses the position: sitting, standing, walking about.
3. Offer warmth and touch if she wants them.
   Massage the lower back; a warm compress or hot water bottle on the sacrum, abdomen or perineum can take the edge off the pain.
4. Second stage: a comfortable position, upright if possible.
   If she is on her back, a small pillow under the right hip — otherwise the baby presses on large blood vessels.
5. Wash your hands with soap and water and put a clean cloth underneath.
6. Support the baby's head as it comes.
   Newborns are slippery. Wipe fluid and mucus away from mouth and nose.
7. Dry the baby with a clean cloth, wrap it, cover its head and put it on the mother's chest or belly at once.
   Keep the mother just as warm.
8. Third stage: wait for the afterbirth and keep it.
   The professionals will still need it.

### cautions
- From here on there are two patients: the mother and the baby.
- Force nothing and pull on nothing. What is written here is accompanying a birth, not delivering one.

## hypothermia
- group: environment
- title: Hypothermia
- when: Shivering, cold pale skin, slowing down, confusion — after cold, wet or wind. When the shivering stops, it is getting dangerous.
- source: European Resuscitation Council (ERC) First Aid Guidelines 2025

### steps
1. Get them out of the cold, out of wind and wet.
2. Take off wet clothing, cutting it off if need be.
3. Wrap them in blankets, underneath as well.
   Cover the head too. The ground takes the most heat.
4. Awake and able to swallow: warm, sweet drinks.
5. Warmth on trunk, neck and head, not on arms and legs.
   A hot water bottle or a heat pad, always with a cloth in between.
6. Call 112 for confusion, for shivering that has stopped, or for drowsiness.

### cautions
- Do not rub arms and legs and do not warm them actively. That drives cold blood to the heart.
- Move them as little as possible. A deeply cold heart can stop from being jolted.
- No alcohol. It feels warm and cools them down.
- In severe hypothermia check breathing and pulse for up to a minute — both may be barely detectable. Nobody is dead until they are warm and dead.

## heat
- group: environment
- title: Heat exhaustion and heatstroke
- when: After heat or exertion: weakness, headache, nausea. If hot dry skin, confusion or unconsciousness join it, it is heatstroke and life-threatening.
- source: German Federal Centre for Health Education (BZgA) and ERC First Aid Guidelines 2025

### steps
1. Get them into shade or a cool room.
2. Lay them down, legs up, loosen clothing.
3. Conscious: let them sip water.
4. Cool them: damp cloths, fan air over them, cold water on neck, armpits and groin.
5. Call 112 for confusion, hot dry skin, vomiting or unconsciousness.
   That is heatstroke. Keep cooling until the ambulance arrives.

### cautions
- Give nothing to drink if they are confused or not fully awake.
- No alcohol and nothing with caffeine.
- Heatstroke is not a bad case of sunburn. Untreated it kills.

## poisoning
- group: environment
- title: Poisoning
- when: Something has been swallowed, breathed in, spilled or got into the eyes that does not belong there.
- source: German poison information centres, Federal Institute for Risk Assessment (BfR)

### steps
1. Your own safety: do not walk into gas or smoke.
2. Call a poison centre. For unconsciousness or difficulty breathing, call 112 first.
3. Have ready what they will ask.
   What, how much, when, how old and how heavy the person is, what symptoms.
4. Keep the packaging, what is left, and any vomit.
5. Skin or eyes affected: rinse for 10 to 15 minutes under running water.
   For an eye, from the inner corner outwards so nothing runs into the good eye.
6. Unconscious and breathing normally: recovery position.

### cautions
- Do not make them vomit. With acids, alkalis and foaming agents the way back up does more harm than the way down.
- No milk. It speeds up the uptake of many poisons.
- No salt water.
- These numbers are a stored snapshot. Check them while you have a network, and put the one that covers you into your emergency contacts.

### facts
- {poisonCentres}

<!--
Mental distress.

These five do not follow the ERC but the IFRC's `International first
aid, resuscitation and education guidelines 2025`. The order of the
actions is theirs, the words are this app's; the guidelines' copyright
page permits non-commercial reproduction with the source named, and
named it is, on every one of these screens.

What is deliberately absent although it is everywhere: the paper bag
and the "five things you can see". The 2025 guidelines explicitly
endorse neither ("Anxiety and panic", the Delphi section). What they
do recommend is breathing with the person, so that is all that is
here.
-->

## frostbite
- group: environment
- title: Frostbite
- when: White, hard, numb patches on fingers, toes, nose or ears.
- source: International first aid, resuscitation and education guidelines 2025 (IFRC), "Frostbite"

### steps
1. Protect them from hypothermia first.
   Move them somewhere warmer, take off wet clothing, keep them dry and warm.
2. Take off jewellery carefully, while that is possible without damaging the skin.
3. Warm the area gently in water at body temperature.
   Usually about 30 minutes, until it is warmed through.
4. Dress it with sterile gauze. Where several digits are affected, put gauze between them.
5. The guidelines additionally put a painkiller up for consideration.
   A high dose of ibuprofen, 400 to 800 mg, or — where that is not available — a low dose of acetylsalicylic acid, 75 to 81 mg. It may improve healing. The amounts are the guidelines', not this app's.

### cautions
- Do not rub and do not handle roughly — that damages the skin.
- Not near direct heat such as a fan heater or a stove.
- Do not break blisters.
- Rewarm only where refreezing is ruled out. Frostbite always needs medical care.

### facts
- Rewarming: body-temperature water, ~30 minutes

## dehydration
- group: environment
- title: Dehydration
- when: After diarrhoea, vomiting, fever or heat: thirst, little and dark urine, weakness.
- source: International first aid, resuscitation and education guidelines 2025 (IFRC), "Dehydration"

### steps
1. Reassure them and give them plenty to drink.
2. Mild case: water is enough.
3. More severe: an oral rehydration solution.
   If there is none: apple juice, coconut water or water.
4. To make it yourself: half a teaspoon of salt and six teaspoons of sugar in one litre of drinking water.
5. Call 112 if they become confused or stop responding.

### cautions
- Nothing alcoholic.
- No rehydration solution during a diabetic high-sugar crisis — it makes the dehydration worse.
- Seek medical advice for babies, children and older people, where more is being lost than taken in, where there is very little or very dark urine, with fever or heat exhaustion, and in doubt.

### facts
- Solution per litre: half tsp salt, 6 tsp sugar
- Children 2 to 5 years: 10 ml per kg

## psychological-first-aid
- group: mentalDistress
- title: Psychological first aid
- when: Somebody is shaken, frozen or beside themselves after an incident. This page applies to all the ones that follow.
- source: International first aid, resuscitation and education guidelines 2025 (IFRC), "Psychological first aid" (Look – Listen – Link, after the WHO)

### steps
1. Safety first, then everything else.
   If the place is not safe, this does not start here — not for you and not for the other person.
2. Look: who needs help, and who needs it most?
   Injuries first. Whoever sits quietly in the corner is easily overlooked; loud is not the same as badly off.
3. Approach calmly, give your name, and say that you want to help.
   At the same height, with no phone in your hand.
4. Listen, and let every reaction stand.
   Crying, anger, silence, indifference — all of it happens, and none of it has to be talked away.
5. Ask what is needed rather than guessing.
   Open questions, and the decision stays with the person. Deciding for themselves again is what settles people.
6. See to what is nearest: warmth, something to drink, a quiet place.
   For a child that means above all finding their caregiver again.
7. Link: to relatives, to reliable information, to further help.
   Say what you know and what you do not. Uncertainty frightens people more than bad news does.

### cautions
- Do not ask for details of what happened. Whoever wants to tell you will tell you — and may stop at any point.
- Do not interpret and do not judge. Psychological first aid is not a conversation about causes and not therapy.
- No help against the person's will, and no touching without permission.
- Do not leave to fetch help without first finding somebody who will look after the person.

### facts
- Crisis helpline, around the clock: 0800 111 0 111
- Crisis helpline, EU-wide: 116 123
- Out-of-hours medical service: 116 117

## suicidal-ideation
- group: mentalDistress
- title: Suicidal thoughts
- when: Somebody says or shows that they do not want to live any more.
- source: International first aid, resuscitation and education guidelines 2025 (IFRC), "Suicidal ideation"; telephone numbers of TelefonSeelsorge Deutschland and Nummer gegen Kummer

### steps
1. Take it seriously. Every mention, including a passing one.
2. Ask directly.
   Talking about it does not make it more likely that somebody does it. Asking openly and gently takes away what is forbidden about the subject.
3. Say from the start that you cannot keep to yourself anything that is life-threatening.
   That belongs at the beginning, not at the end — otherwise it is a breach of trust instead of a condition.
4. Do not leave the person alone.
   On the phone: ask where they are and who they trust.
5. Have them put away anything they could hurt themselves with.
   Medicines, tools, weapons. Better still if somebody in the household helps with it.
6. Make the place safe.
   A quiet room lower down the building, windows shut, away from anything dangerous.
7. Get help together — call while you are there, do not send them off with a task.
   Crisis line, family doctor, community mental health service, psychiatric hospital.
8. In immediate danger, or after an attempt: 112.
   After an attempt, physical first aid comes first — bleeding, poisoning, unconsciousness.

### cautions
- Do not promise to keep it to yourself. That is a promise nobody can keep.
- Do not judge and do not argue. What helps is listening.
- Do not walk away to fetch help. First make sure somebody stays.
- This page is no substitute for training. It is meant to make you aware, not expert.

### facts
- Crisis helpline, around the clock: 0800 111 0 111
- Crisis helpline, second number: 0800 111 0 222
- Crisis helpline, EU-wide: 116 123
- Children and young people: 116 111
- Emergency number, immediate danger: 112

## anxiety-panic
- group: mentalDistress
- title: Anxiety and panic attack
- when: Racing heart, breathlessness, a tight chest, the fear of dying — and after minutes it recedes by itself.
- source: International first aid, resuscitation and education guidelines 2025 (IFRC), "Anxiety and panic"

### steps
1. Introduce yourself and say that you are staying.
2. Move to a quiet place, away from onlookers.
   Loosen tight clothing.
3. Ask whether they have had this before.
   Somebody who recognises the attack has already lost half the fear of it.
4. Say that it is a reaction to strain and that it eases by itself.
   The peak is past after ten to fifteen minutes.
5. Speak slowly and quietly, in short sentences.
6. Breathe in front of them and have them breathe with you.
   In through the nose for one count, out through the mouth for three, and let the breath go into the belly.
7. Say there is nothing shameful about it and nobody is going mad.
8. Stay until it is over.
   If it happens repeatedly, or somebody arranges their life around it, advise a doctor: there is effective help.

### cautions
- No paper bag over the mouth. The 2025 guidelines endorse neither that nor similar home remedies; what they recommend is breathing with the person.
- Not "calm down" and not "there is nothing there". The fear is real even when the danger is not.
- If in doubt whether it is a panic attack or an emergency: 112. Chest pain and breathlessness can come from the heart.

### facts
- Peak of the attack: after 10 to 15 minutes
- Breathing: in for 1, out for 3
- Crisis helpline, EU-wide: 116 123

## traumatic-event
- group: mentalDistress
- title: After a traumatic event
- when: Shortly after an accident, a disaster or violence — for those affected and for helpers.
- source: International first aid, resuscitation and education guidelines 2025 (IFRC), "Traumatic event"

### steps
1. The physical first: stop the bleeding, treat, resuscitate.
   Stay calm and present while you do. Both happen at once.
2. Say what you are doing, in short and simple sentences.
3. Stay, listen, and let the feelings stand.
4. Let the person share in the decisions about their care.
   Being asked and allowed to choose hands back a piece of control.
5. Bring in relatives or friends where you can.
6. Tell the ambulance crew how the person is, physically and emotionally.

### cautions
- Do not press them to talk and do not ask for details.
- Strong reactions in the first days are ordinary and not yet an illness.
- They can also arrive weeks or months later. If they persist or worsen, that belongs in a doctor's hands.

### facts
- Out-of-hours medical service: 116 117
- Crisis helpline, EU-wide: 116 123

## acute-grief
- group: mentalDistress
- title: Acute grief
- when: Somebody has just learned that a person has died.
- source: International first aid, resuscitation and education guidelines 2025 (IFRC), "Acute grief"

### steps
1. Introduce yourself and say you are there, if the person does not know you.
2. Move somewhere safe and make room.
   Nobody should feel crowded.
3. Ask directly what you can help with.
4. Be fully there and let every reaction stand.
   Shock, anger, guilt, indifference — after a sudden death all of that is ordinary.
5. Ask whether they would like to see the person who died, where that is possible.
   Say beforehand how they will look. Time with the body eases grieving and takes away guilt.
6. Help them reach relatives rather than being left alone.
7. Encourage breaks — something to do that takes the mind elsewhere for a while.

### cautions
- Do not leave without having satisfied yourself that they are all right.
- No comparisons and no deadlines. Grief has no duration after which it is meant to be over.
- Do not tell the person what they ought to be feeling.

### facts
- Crisis helpline, around the clock: 0800 111 0 111
- Crisis helpline, EU-wide: 116 123
