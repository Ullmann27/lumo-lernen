export const allowedTopicHints = [
  'Volksschule',
  'Mathehilfe',
  'Deutschhilfe',
  'Englischhilfe',
  'Lesen',
  'Schreiben',
  'Sachunterricht',
  'Geografie fuer Kinder',
  'Natur und Tiere',
  'Pflanzen',
  'Wetter',
  'Freundschaft',
  'Alltag',
  'kindgerechte Filme und Cartoons',
  'Disney- und Maerchen-Gespraeche ohne Gewalt',
  'Lernspiele',
];

export const blockedTopicRules = [
  {
    id: 'sexual_content',
    severity: 'block',
    terms: ['sex', 'sexy', 'porno', 'pornografie', 'nackt', 'nacktheit', 'nacktbilder', 'onlyfans', 'kuessen mit zunge', 'vergewaltigung', 'erektion', 'masturbation'],
    redirect: 'Darueber spreche ich mit Kindern nicht. Lass uns lieber ueber Schule, Freunde oder eine spannende Geschichte reden.',
  },
  {
    id: 'graphic_violence_war_weapons',
    severity: 'block',
    terms: ['krieg', 'gewalt', 'waffe', 'messer', 'pistole', 'gewehr', 'bombe', 'toeten', 'mord', 'blut', 'hinrichten', 'folter', 'anschlag', 'schiessen', 'erschiessen', 'stechen', 'pruegeln'],
    redirect: 'Das ist kein gutes Thema fuer unsere Lernzeit. Wir koennen ueber Mut, Hilfe holen oder ein friedliches Abenteuer sprechen.',
  },
  {
    id: 'self_harm_or_suicide',
    severity: 'safe_redirect',
    terms: ['ich will sterben', 'mich umbringen', 'suizid', 'selbstmord', 'ritzen', 'mir weh tun', 'mich verletzen'],
    redirect: 'Das klingt sehr ernst. Bitte sag sofort einem Erwachsenen in deiner Naehe Bescheid. Ich bleibe freundlich bei dir und wir holen Hilfe.',
  },
  {
    id: 'politics_extremism',
    severity: 'block',
    terms: ['partei', 'wahlkampf', 'hitler', 'nazi', 'terror', 'terrorist', 'extremismus', 'propaganda', 'rassist', 'rassismus'],
    redirect: 'Darueber reden wir in Lumo Lernen nicht. Ich kann dir aber eine neutrale Schulfrage oder ein Naturthema erklaeren.',
  },
  {
    id: 'hate_speech',
    severity: 'block',
    terms: ['hassen alle', 'ich hasse', 'auslaender raus', 'minderwertig', 'sind dumm', 'verachten'],
    redirect: 'So reden wir nicht ueber andere Menschen. Lass uns ueber etwas Positives oder eine Lernfrage sprechen.',
  },
  {
    id: 'drugs_alcohol',
    severity: 'block',
    terms: ['drogen', 'kiffen', 'kokain', 'heroin', 'cannabis', 'gras rauchen', 'alkohol trinken', 'betrunken', 'zigarette', 'rauchen anleitung', 'vape', 'e-zigarette'],
    redirect: 'Das ist kein Kinderthema. Lass uns ueber gesunde Gewohnheiten, Sport oder eine Lernaufgabe sprechen.',
  },
  {
    id: 'private_data',
    severity: 'block',
    terms: ['adresse', 'telefonnummer', 'handynummer', 'passwort', 'bankkarte', 'kreditkarte', 'pin code', 'geheimnis verraten', 'meine schule heisst', 'wohne in der'],
    redirect: 'Private Daten bleiben geheim. Teile nie Adresse, Passwort oder Telefonnummer. Wollen wir lieber eine Aufgabe ueben?',
  },
  {
    id: 'stranger_danger',
    severity: 'safe_redirect',
    terms: ['fremder hat mir', 'fremder will', 'will mich treffen', 'wir treffen uns heimlich', 'sag es deinen eltern nicht', 'sag es deiner mama nicht', 'sag es niemandem', 'unser geheimnis', 'ich darf nicht reden'],
    redirect: 'Das ist wichtig. Erzaehl bitte sofort einem Erwachsenen in deiner Familie davon. Du musst kein Geheimnis fuer dich behalten, das dich unwohl fuehlen laesst.',
  },
];

export function inspectChildSafety(message) {
  const text = String(message || '').toLowerCase();
  for (const rule of blockedTopicRules) {
    if (rule.terms.some((term) => text.includes(term))) {
      return {
        allowed: false,
        ruleId: rule.id,
        severity: rule.severity,
        redirect: rule.redirect,
      };
    }
  }
  return { allowed: true, ruleId: null, severity: 'allow', redirect: null };
}

export function buildLumoSystemPrompt() {
  return `Du bist Lumo, ein freundlicher Lernfuchs fuer Kinder in der Volksschule.\n\nPflichten:\n- Sprich kindgerecht, warm, kurz und ruhig.\n- Hilf bei Mathe, Deutsch, Lesen, Schreiben, Englisch, Sachunterricht, Geografie fuer Kinder, Natur, Tiere, Pflanzen, Wetter, Freundschaft und Alltag.\n- Erklaere Aufgaben in kleinen Schritten.\n- Stelle am Ende oft eine einfache Rueckfrage oder biete eine Lernaufgabe an.\n- Keine Beschämung, kein Druck, keine Angst.\n\nStrikte Verbote:\n- Keine sexuellen Inhalte.\n- Keine Gewalt-, Waffen-, Kriegs- oder Horror-Erklaerungen.\n- Keine politischen Diskussionen oder extremistischen Inhalte.\n- Keine Drogen-, Alkohol- oder Nikotin-Tipps.\n- Keine privaten Daten abfragen.\n- Keine Diagnose, Therapie oder Rechtsberatung.\n\nWenn ein Kind ein verbotenes Thema anspricht:\n- Kurz freundlich stoppen.\n- Keine Details geben.\n- Zu Schule, Freunden, Natur, Lesen oder einer Aufgabe umlenken.\n\nWenn ein Kind von Gefahr, Selbstverletzung oder ernstem Leid spricht:\n- Sage ruhig, dass es sofort einem Erwachsenen Bescheid sagen soll.\n- Keine langen Diskussionen.\n- Keine technischen Anleitungen.\n\nAntwortformat:\n- Maximal 6 kurze Saetze.\n- Fuer Lernhilfe: Schritt 1, Schritt 2, Mini-Frage.\n- Immer auf Deutsch, ausser das Kind uebt Englisch.`;
}
