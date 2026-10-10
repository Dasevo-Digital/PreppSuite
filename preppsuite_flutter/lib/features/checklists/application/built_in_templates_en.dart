/// The built-in checklists in English (#108), by each row's clientId.
///
/// Shown in place of the German text only while a row still says exactly
/// what was shipped -- see `built_in_template_l10n.dart`. Legal references
/// stay German law: "Required" in the vehicle list means required by the
/// German StVZO, and says so.
library;

const builtInChecklistsEn = <String, String>{
  // Wasser
  '00000000-0000-4000-8000-000000000001': 'Water',
  '00000000-0000-4000-8000-000000000102':
      'Water canisters or containers — also for firefighting and household '
      'water, as the BBK’s list puts it',
  '00000000-0000-4000-8000-000000000103': 'Water filter or water disinfectant',
  // Erste Hilfe
  '00000000-0000-4000-8000-000000000002': 'First aid',
  '00000000-0000-4000-8000-000000000201': 'First aid kit (DIN 13157)',
  '00000000-0000-4000-8000-000000000202': 'Clinical thermometer',
  '00000000-0000-4000-8000-000000000203':
      'Regular medication (enough in stock)',
  '00000000-0000-4000-8000-000000000204': 'First aid booklet',
  // Lebensmittel
  '00000000-0000-4000-8000-000000000003': 'Food',
  '00000000-0000-4000-8000-000000000301':
      'Grain products, bread, potatoes, pasta, rice (3.5 kg per person for '
      '10 days)',
  '00000000-0000-4000-8000-000000000302':
      'Vegetables and pulses, canned for instance (4 kg per person for 10 '
      'days)',
  '00000000-0000-4000-8000-000000000303':
      'Fruit and nuts (2.5 kg per person for 10 days)',
  '00000000-0000-4000-8000-000000000304':
      'Milk and dairy (2.6 kg per person for 10 days)',
  '00000000-0000-4000-8000-000000000305':
      'Fish, meat, eggs or dried whole egg (1.5 kg per person for 10 days)',
  '00000000-0000-4000-8000-000000000306':
      'Fats and oils (0.35 kg per person for 10 days)',
  '00000000-0000-4000-8000-000000000307':
      'Supplies that can be eaten without cooking',
  // Hygiene
  '00000000-0000-4000-8000-000000000004': 'Hygiene',
  '00000000-0000-4000-8000-000000000401': 'Soap and hand sanitiser',
  '00000000-0000-4000-8000-000000000402': 'Laundry detergent',
  '00000000-0000-4000-8000-000000000403': 'Toothbrush and toothpaste',
  '00000000-0000-4000-8000-000000000404': 'Toilet paper and wet wipes',
  '00000000-0000-4000-8000-000000000405': 'Bin bags, large and tear-resistant',
  '00000000-0000-4000-8000-000000000406': 'Household gloves',
  '00000000-0000-4000-8000-000000000407':
      'Camping toilet or a bucket with a tight-fitting lid — without water '
      'no toilet flushes',
  '00000000-0000-4000-8000-000000000408':
      'Whatever else this household needs: menstrual products, nappies, '
      'incontinence supplies',
  // Strom- und Heizungsausfall
  '00000000-0000-4000-8000-000000000005': 'Power and heating failure',
  '00000000-0000-4000-8000-000000000501': 'Torch and spare batteries',
  '00000000-0000-4000-8000-000000000502':
      'Candles, matches or a lighter — never leave candles burning '
      'unattended',
  '00000000-0000-4000-8000-000000000503':
      'Camping stove with fuel — outdoors or well ventilated only, never in '
      'a closed room',
  '00000000-0000-4000-8000-000000000504':
      'Wood or coal, if there is a stove or fireplace',
  '00000000-0000-4000-8000-000000000505': 'Charged power bank for the phone',
  '00000000-0000-4000-8000-000000000506':
      'Warm clothing, blankets, sleeping bags',
  '00000000-0000-4000-8000-000000000507':
      'Batteries in the sizes the household uses',
  // Informiert bleiben
  '00000000-0000-4000-8000-000000000006': 'Staying informed',
  '00000000-0000-4000-8000-000000000601':
      'Battery or wind-up radio for FM and DAB+',
  '00000000-0000-4000-8000-000000000602': 'Spare batteries for the radio',
  '00000000-0000-4000-8000-000000000603':
      'Car radio as the fallback when nothing else works',
  '00000000-0000-4000-8000-000000000604':
      'Important phone numbers on paper — a flat phone gives none of them up',
  '00000000-0000-4000-8000-000000000605':
      'Emergency numbers: 112 for fire and ambulance, 110 for the police',
  '00000000-0000-4000-8000-000000000606':
      'The BBK’s warning app NINA on the phone',
  // Wichtige Dokumente
  '00000000-0000-4000-8000-000000000007': 'Important documents',
  '00000000-0000-4000-8000-000000000701':
      'Document folder, within reach in a fixed place',
  '00000000-0000-4000-8000-000000000702': 'ID card, passport, driving licence',
  '00000000-0000-4000-8000-000000000703':
      'Birth, marriage and death certificates',
  '00000000-0000-4000-8000-000000000704':
      'Vaccination record, allergy card, medication plan',
  '00000000-0000-4000-8000-000000000705': 'Insurance policies',
  '00000000-0000-4000-8000-000000000706':
      'Land register extract, tenancy or purchase contracts',
  '00000000-0000-4000-8000-000000000707': 'Pension, income and tax statements',
  '00000000-0000-4000-8000-000000000708':
      'School and work certificates, proof of qualifications',
  '00000000-0000-4000-8000-000000000709':
      'Certified copies, kept apart from the originals',
  '00000000-0000-4000-8000-000000000710':
      'Digital copies on a USB stick in the folder',
  // Notgepäck
  '00000000-0000-4000-8000-000000000008': 'Emergency bag',
  '00000000-0000-4000-8000-000000000801':
      'One rucksack per person that they can carry on their own',
  '00000000-0000-4000-8000-000000000802':
      'Personal medication and a small medicine kit',
  '00000000-0000-4000-8000-000000000803': 'Document folder',
  '00000000-0000-4000-8000-000000000804':
      'Food and drink for two to three days',
  '00000000-0000-4000-8000-000000000805':
      'Plate and cutlery, pocket knife, tin opener',
  '00000000-0000-4000-8000-000000000806':
      'Weatherproof clothing, a change of clothes, sturdy shoes',
  '00000000-0000-4000-8000-000000000807': 'Sleeping bag or blanket',
  '00000000-0000-4000-8000-000000000808': 'Travel-size toiletries',
  '00000000-0000-4000-8000-000000000809': 'Torch, radio, spare batteries',
  '00000000-0000-4000-8000-000000000810':
      'Cash in small notes — card payment needs power',
  '00000000-0000-4000-8000-000000000811': 'Phone, charging cable, power bank',
  // Sicherheit im Haus
  '00000000-0000-4000-8000-000000000009': 'Safety at home',
  '00000000-0000-4000-8000-000000000901':
      'Smoke alarms in bedrooms, children’s rooms and the hallway, tested '
      'once a year',
  '00000000-0000-4000-8000-000000000902': 'Inspected fire extinguisher',
  '00000000-0000-4000-8000-000000000903': 'Fire blanket for the kitchen',
  '00000000-0000-4000-8000-000000000904':
      'Carbon monoxide alarm if gas or solid fuel is used for heating or '
      'cooking',
  '00000000-0000-4000-8000-000000000905':
      'Keep escape routes clear and walk through them with everyone in the '
      'household',
  '00000000-0000-4000-8000-000000000906':
      'Agree on a meeting point outside the house',
  '00000000-0000-4000-8000-000000000907':
      'Know where the shut-offs for gas, water and electricity are, and be '
      'able to reach them',
  // Haustiere
  '00000000-0000-4000-8000-000000000010': 'Pets',
  '00000000-0000-4000-8000-000000001001': 'Food for at least ten days',
  '00000000-0000-4000-8000-000000001002':
      'Drinking water for the animals — the supply calculator counts it in',
  '00000000-0000-4000-8000-000000001003': 'Carrier box or bag for each animal',
  '00000000-0000-4000-8000-000000001004': 'Lead, collar, muzzle',
  '00000000-0000-4000-8000-000000001005':
      'Vaccination record and microchip or tattoo number',
  '00000000-0000-4000-8000-000000001006': 'The animal’s medication',
  '00000000-0000-4000-8000-000000001007': 'Blanket and a familiar toy',
  '00000000-0000-4000-8000-000000001008': 'Poo bags, cat litter, bedding',
  '00000000-0000-4000-8000-000000001009':
      'Arrange emergency care (neighbours, boarding kennel, animal shelter) '
      'and note it on the animal’s emergency card',
  // Hochwasser und Starkregen
  '00000000-0000-4000-8000-000000000011': 'Floods and heavy rain',
  '00000000-0000-4000-8000-000000001101':
      'Check the federal state’s flood hazard map to see whether the address '
      'can be affected',
  '00000000-0000-4000-8000-000000001102':
      'Backflow valves in the drains — checked once a year',
  '00000000-0000-4000-8000-000000001103':
      'Protect basement windows and light wells against water coming in',
  '00000000-0000-4000-8000-000000001104':
      'Secure the oil tank and heating system so that water cannot lift them',
  '00000000-0000-4000-8000-000000001105':
      'Check natural hazard insurance — in Germany, standard buildings '
      'insurance does not cover floods',
  '00000000-0000-4000-8000-000000001106':
      'Keep nothing irreplaceable in the basement',
  '00000000-0000-4000-8000-000000001107':
      'Submersible pump, hoses and sandbags within reach',
  '00000000-0000-4000-8000-000000001108':
      'Know where to switch off the basement circuit',
  // Hitze und Dürre
  '00000000-0000-4000-8000-000000000012': 'Heat and drought',
  '00000000-0000-4000-8000-000000001201':
      'Air the rooms at night and early in the morning, keep windows and '
      'shutters closed during the day',
  '00000000-0000-4000-8000-000000001202':
      'Drink more than usual, even without feeling thirsty',
  '00000000-0000-4000-8000-000000001203': 'Light meals, little alcohol',
  '00000000-0000-4000-8000-000000001204':
      'Do strenuous things in the cool hours',
  '00000000-0000-4000-8000-000000001205':
      'Keep medicines cool — many do not tolerate 25 degrees; the package '
      'leaflet says',
  '00000000-0000-4000-8000-000000001206':
      'Some medicines act differently in the heat — go through them once '
      'with the GP’s practice',
  '00000000-0000-4000-8000-000000001207': 'Pick a cool room in the home',
  '00000000-0000-4000-8000-000000001208':
      'Check on elderly neighbours and those living alone',
  '00000000-0000-4000-8000-000000001209':
      'Never leave children or animals in the car',
  '00000000-0000-4000-8000-000000001210':
      'Know the signs of heatstroke: headache, nausea, confusion, hot dry '
      'skin',
  '00000000-0000-4000-8000-000000001211':
      'In dry weather: no fires and no smoking in the woods, no parking on '
      'dry grass',
  // Sturm, Kälte und Schnee
  '00000000-0000-4000-8000-000000000013': 'Storm, cold and snow',
  '00000000-0000-4000-8000-000000001301':
      'Secure loose objects on the balcony, terrace and in the garden before '
      'the storm arrives',
  '00000000-0000-4000-8000-000000001303':
      'Have the roof, gutters and trees near the house checked regularly',
  '00000000-0000-4000-8000-000000001304':
      'Keep an eye on the snow load on flat roofs, carports and '
      'conservatories',
  '00000000-0000-4000-8000-000000001305':
      'Have the heating serviced before winter',
  '00000000-0000-4000-8000-000000001306':
      'Protect water pipes in unheated rooms against frost',
  '00000000-0000-4000-8000-000000001307':
      'For a heating failure: warm clothing, blankets, sleeping bags — and '
      'fuel if there is a stove',
  '00000000-0000-4000-8000-000000001308': 'Grit and a snow shovel',
  '00000000-0000-4000-8000-000000001309':
      'In the car: blanket, shovel, warm things — and in winter, never drive '
      'on an almost empty tank',
  // Schutz suchen
  '00000000-0000-4000-8000-000000000014': 'Seeking shelter',
  '00000000-0000-4000-8000-000000001401':
      'Pick the safest room in the home: inside, without windows, ideally at '
      'the core of the building',
  '00000000-0000-4000-8000-000000001402':
      'In a storm or severe weather: a lower floor, away from windows',
  '00000000-0000-4000-8000-000000001403':
      'In a flood: upstairs, never into the basement',
  '00000000-0000-4000-8000-000000001404':
      'If hazardous substances are released: get inside, close windows and '
      'doors, ventilation and air conditioning off, radio on',
  '00000000-0000-4000-8000-000000001405':
      'In an explosion or tremor: away from glass and glazed fronts',
  '00000000-0000-4000-8000-000000001406':
      'Know which solid building nearby would offer shelter',
  '00000000-0000-4000-8000-000000001407':
      'Know the escape routes out of the building, in the dark too',
  '00000000-0000-4000-8000-000000001408':
      'A meeting point in case the household is separated — it is also in '
      'the emergency plan',
  '00000000-0000-4000-8000-000000001409':
      'Know who in the neighbourhood can help and who needs help',
  // Mit Ängsten und Sorgen umgehen
  '00000000-0000-4000-8000-000000000015': 'Dealing with fear and worry',
  '00000000-0000-4000-8000-000000001501':
      'Fixed times for the news, and switching off on purpose in between',
  '00000000-0000-4000-8000-000000001502':
      'Reliable sources only: official warnings and public broadcasting',
  '00000000-0000-4000-8000-000000001503':
      'Keep a daily routine — sleep, meals, exercise',
  '00000000-0000-4000-8000-000000001504':
      'Talk to others instead of brooding alone',
  '00000000-0000-4000-8000-000000001505':
      'Talk to children in a way that suits their age, take their questions '
      'seriously and do not play things down',
  '00000000-0000-4000-8000-000000001506':
      'Show children what the household has prepared — preparation takes '
      'away fear',
  '00000000-0000-4000-8000-000000001507':
      'Watch for signs: sleeplessness, irritability, withdrawal',
  '00000000-0000-4000-8000-000000001508':
      'Telefonseelsorge, the German crisis line: 0800 111 0 111 and 0800 111 '
      '0 222, around the clock and free of charge',
  '00000000-0000-4000-8000-000000001509':
      'Know who in the household will most need support in a crisis',
  // Säuglinge, Pflege und Barrierefreiheit
  '00000000-0000-4000-8000-000000000016': 'Babies, care and accessibility',
  '00000000-0000-4000-8000-000000001601':
      'Baby food and boiled water for ten days',
  '00000000-0000-4000-8000-000000001602': 'Nappies, wet wipes, changing mat',
  '00000000-0000-4000-8000-000000001603':
      'Care supplies for ten days: incontinence products, dressings, '
      'disinfectant',
  '00000000-0000-4000-8000-000000001604':
      'Spare batteries and chargers for hearing aid, wheelchair, care bed',
  '00000000-0000-4000-8000-000000001605':
      'For every device that needs power, settle on a manual alternative',
  '00000000-0000-4000-8000-000000001606':
      'Medication plan and care records in the document folder',
  '00000000-0000-4000-8000-000000001607':
      'Settle who helps with leaving the home when the lift is not working',
  '00000000-0000-4000-8000-000000001608':
      'Let neighbours and the care service know who in the house needs help',
  '00000000-0000-4000-8000-000000001609':
      'Fill in an emergency card for each person — in PreppSuite under '
      'Household',
  // Hausapotheke
  '00000000-0000-4000-8000-000000000017': 'Medicine cabinet',
  '00000000-0000-4000-8000-000000001701': 'Painkillers and fever reducers',
  '00000000-0000-4000-8000-000000001702': 'Remedies for cold symptoms',
  '00000000-0000-4000-8000-000000001703':
      'Remedies for diarrhoea, vomiting and nausea',
  '00000000-0000-4000-8000-000000001704':
      'Electrolytes to replace lost fluid — with diarrhoea the danger is '
      'drying out, not the diarrhoea',
  '00000000-0000-4000-8000-000000001705':
      'Decongestant nose drops or nasal spray',
  '00000000-0000-4000-8000-000000001706': 'Skin and wound disinfectant',
  '00000000-0000-4000-8000-000000001707': 'Ointment for burns and wounds',
  '00000000-0000-4000-8000-000000001708':
      'Something for sunburn and insect bites',
  '00000000-0000-4000-8000-000000001709': 'Cooling gel for sprains and bruises',
  '00000000-0000-4000-8000-000000001710':
      'Check expiry dates — entered in the inventory, the app reminds you of '
      'them by itself',
  // Falschmeldungen erkennen
  '00000000-0000-4000-8000-000000000018': 'Spotting false reports',
  '00000000-0000-4000-8000-000000001801':
      'Who published it first? Sender, real name, legal notice',
  '00000000-0000-4000-8000-000000001802':
      'Are sources named that can be checked?',
  '00000000-0000-4000-8000-000000001803':
      'Does a second reliable source report the same?',
  '00000000-0000-4000-8000-000000001804':
      'A single "no" to these three questions is enough not to pass it on',
  '00000000-0000-4000-8000-000000001805':
      'A picture can be genuine and still be from two years ago — ask about '
      'date and place, not only whether it is real',
  '00000000-0000-4000-8000-000000001806':
      'Official warnings are in PreppSuite with their source — look there '
      'rather than in forwarded messages',
  '00000000-0000-4000-8000-000000001807':
      'When in doubt, ask the local council or the emergency control centre, '
      'not the group chats',
  '00000000-0000-4000-8000-000000001808':
      'Public broadcasting on the radio when the network is down or '
      'overloaded',
  '00000000-0000-4000-8000-000000001809':
      'Question it instead of forwarding it — a false report you shared '
      'yourself comes back looking like confirmation',
  // Wenn der Strom ausfällt
  '00000000-0000-4000-8000-000000000019': 'When the power goes out',
  '00000000-0000-4000-8000-000000001910':
      'Without power, water stops coming out of the tap too — then only your '
      'own drinking water counts',
  '00000000-0000-4000-8000-000000001901':
      'Keep the fridge and freezer closed — every opening costs hours',
  '00000000-0000-4000-8000-000000001902':
      'Generator and fuel outdoors only, at least 6 metres from windows, '
      'doors and an attached garage',
  '00000000-0000-4000-8000-000000001903':
      'A carbon monoxide alarm on every floor — the gas has no colour and no '
      'smell',
  '00000000-0000-4000-8000-000000001904':
      'Stoves, grills and charcoal outdoors only, never in the home, '
      'basement or garage',
  '00000000-0000-4000-8000-000000001905':
      'Unplug appliances and electronics — the power comes back as a surge',
  '00000000-0000-4000-8000-000000001906':
      'For powered medical devices, make a plan with the doctor’s practice '
      'beforehand',
  '00000000-0000-4000-8000-000000001907':
      'For medicines that must be kept cold: ask beforehand how long they '
      'may be kept warmer',
  '00000000-0000-4000-8000-000000001908':
      'Perishable food that has been above 4 °C for two hours goes — and '
      'never taste it to decide',
  // Hochwasser: wenn es soweit ist
  '00000000-0000-4000-8000-000000000020': 'Flood: when it happens',
  '00000000-0000-4000-8000-000000002001':
      'Do not go into the basement. Not briefly, not to save things — rooms '
      'fill faster than you can get out',
  '00000000-0000-4000-8000-000000002002':
      'Switch off appliances and heating in rooms that can flood; if in '
      'doubt, switch the power off entirely (fuses out)',
  '00000000-0000-4000-8000-000000002003':
      'Seal windows, doors and drain openings',
  '00000000-0000-4000-8000-000000002004':
      'Move the car out of the garage and underground car park in good time '
      '— in a flood an underground car park becomes a trap',
  '00000000-0000-4000-8000-000000002005':
      'Do not drive or wade through flooded roads; you cannot see whether '
      'the road surface is still there',
  '00000000-0000-4000-8000-000000002006':
      'Stay away from riverbanks — they can be undercut and give way',
  '00000000-0000-4000-8000-000000002007':
      'Follow water levels and warnings, radio on, follow the emergency '
      'services’ instructions',
  '00000000-0000-4000-8000-000000002008':
      'Check on neighbours who cannot get upstairs by themselves',
  '00000000-0000-4000-8000-000000002009':
      'Afterwards: enter flooded basements only once the power is known to '
      'be off',
  // Sturm und Unwetter: wenn es soweit ist
  '00000000-0000-4000-8000-000000000021':
      'Storm and severe weather: when it happens',
  '00000000-0000-4000-8000-000000002101':
      'Stay inside the building, not under trees and not next to the facade',
  '00000000-0000-4000-8000-000000002102':
      'Close all windows, the roof windows too, and lower the shutters',
  '00000000-0000-4000-8000-000000002103':
      'Into an inner room on the ground floor — not the basement, which can '
      'flood in heavy rain',
  '00000000-0000-4000-8000-000000002104':
      'Not into the attic and not onto the roof while the wind is blowing',
  '00000000-0000-4000-8000-000000002105': 'Unplug sensitive devices',
  '00000000-0000-4000-8000-000000002106':
      'If the roof is badly damaged, keep well away from the house',
  '00000000-0000-4000-8000-000000002107':
      'Afterwards: report fallen power lines, never touch them yourself',
  '00000000-0000-4000-8000-000000002108':
      'Afterwards: photograph the damage before clearing up',
  // Fahrzeug
  '00000000-0000-4000-8000-000000000024': 'Vehicle',
  '00000000-0000-4000-8000-000000002201':
      'Required: a warning triangle (German StVZO § 53a(2) no. 1)',
  '00000000-0000-4000-8000-000000002202':
      'Required: a high-visibility vest to DIN EN 471 or EN ISO 20471 '
      '(German StVZO § 53a(2) no. 3)',
  '00000000-0000-4000-8000-000000002203':
      'Required: a first aid kit to DIN 13164, 1998 or 2014 edition, in a '
      'closed container (German StVZO § 35h(3))',
  '00000000-0000-4000-8000-000000002204':
      'Check the expiry date in the first aid kit — the law requires the '
      'kit, not its age, but old material no longer sticks',
  '00000000-0000-4000-8000-000000002205':
      'Not required, but sensible: one high-visibility vest per seat, within '
      'reach inside the car and not in the boot',
  '00000000-0000-4000-8000-000000002206':
      'Never let the tank or battery drop below half',
  '00000000-0000-4000-8000-000000002207':
      'Tyre pressure, tread depth and spare wheel or repair kit checked',
  '00000000-0000-4000-8000-000000002208':
      'Oil, coolant and screenwash topped up',
  '00000000-0000-4000-8000-000000002209':
      'All lights checked, spare bulbs on board',
  '00000000-0000-4000-8000-000000002210': 'Jump leads and tow rope',
  '00000000-0000-4000-8000-000000002211':
      'Torch or head torch with charged batteries',
  '00000000-0000-4000-8000-000000002212':
      'Charged power bank and charging cable for the phone',
  '00000000-0000-4000-8000-000000002213':
      'Water and something long-lasting to eat in the vehicle',
  '00000000-0000-4000-8000-000000002214':
      'Blanket, sturdy shoes and a rain jacket',
  '00000000-0000-4000-8000-000000002215':
      'Cash in small notes — card payment fails along with the power',
  '00000000-0000-4000-8000-000000002216':
      'Paper map of the area, for when there is no network and no battery',
  '00000000-0000-4000-8000-000000002217':
      'Meeting point and alternative route agreed with family',
  '00000000-0000-4000-8000-000000002218':
      'Winter: ice scraper, hand brush, antifreeze in the screenwash, '
      'blanket',
  '00000000-0000-4000-8000-000000002219':
      'Winter: snow chains where they are needed — and fitted once for '
      'practice',
  '00000000-0000-4000-8000-000000002220':
      'Summer: sun protection and water even for short trips',
  '00000000-0000-4000-8000-000000002221':
      'Park the vehicle so that it can leave without manoeuvring',
  // Pflege zu Hause: Vorsorge für Angehörige (AOK)
  '00000000-0000-4000-8000-000000000025':
      'Care at home: preparing for relatives (AOK)',
  '00000000-0000-4000-8000-000000002501':
      'Agree a support network: who takes on what and for how long, who '
      'coordinates, who has the keys – ask the immediate neighbours too',
  '00000000-0000-4000-8000-000000002502':
      'Plan care without the care service; ask the care service what it can '
      'do in an emergency',
  '00000000-0000-4000-8000-000000002503':
      'Show everyone helping the care tasks they will need, for instance '
      'through a care course',
  '00000000-0000-4000-8000-000000002504':
      'The GP and the care service know whether ventilators or oxygen '
      'equipment are needed',
  '00000000-0000-4000-8000-000000002505':
      'Make a power-cut plan with the doctor’s practice, including how long '
      'refrigerated medicines stay usable at the wrong temperature',
  '00000000-0000-4000-8000-000000002506':
      'Thermometers in the fridge and freezer',
  '00000000-0000-4000-8000-000000002507':
      'With oxygen or ventilation: keep the necessary supplies and extra '
      'batteries ready',
  '00000000-0000-4000-8000-000000002508':
      'With an electric alternating-pressure mattress: keep an ordinary foam '
      'mattress in reserve',
  '00000000-0000-4000-8000-000000002509':
      'With puréed food: puréed food in jars and a supply of drinkable '
      'nutrition, because the blender stops without power',
  '00000000-0000-4000-8000-000000002510':
      'Care supplies for several days: disposable gloves, hand sanitiser, '
      'incontinence products, injection needles, insulin pen',
  '00000000-0000-4000-8000-000000002511':
      'Medicines for several days in the house',
  '00000000-0000-4000-8000-000000002512':
      'Bin bags and a lidded bin for waste and excreta',
  '00000000-0000-4000-8000-000000002513':
      'Thermos jugs or flasks for hot water and drinks',
  '00000000-0000-4000-8000-000000002514':
      'The home emergency alarm, phone and doorbell stop without power: '
      'agree knocking or light signals with neighbours and put a paper phone '
      'list next to the phone',
  '00000000-0000-4000-8000-000000002515':
      'Settle how the person in care can be evacuated in time and who takes '
      'them in outside the danger zone',
  '00000000-0000-4000-8000-000000002516':
      'Emergency bag: phone list, medicines, ID, cash, health insurance '
      'card, vaccination record, keys, charged phone, toiletries and care '
      'supplies for a few days, clothes',
};
