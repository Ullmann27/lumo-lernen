// These situations assess choices in a story. The speakers give the clues.
// Multiple considerate responses are possible, and each has its own feedback.
typedef EmotionChoice = ({String text, String feedback});
typedef EmotionScene = ({
  String title,
  String story,
  String prompt,
  List<EmotionChoice> choices,
});

List<EmotionScene> emotionScenesFor(int grade) => grade < 3 ? _early : _later;

const _early = <EmotionScene>[
  (
    title: 'Der Turm fällt',
    story:
        'Miras Turm fällt um. „Oh nein! Ich habe so lange gebaut“, sagt sie.',
    prompt: 'Was könntest du Mira sagen?',
    choices: [
      (
        text: '„Das ist ärgerlich. Soll ich helfen?“',
        feedback:
            'Du hörst, wie viel Zeit Mira in den Turm gesteckt hat. Sie darf selbst entscheiden, ob sie Hilfe möchte.'
      ),
      (
        text: '„Ich baue ihn sofort für dich.“',
        feedback:
            'Du willst helfen. Frag Mira zuerst, ob sie selbst weiterbauen möchte.'
      ),
      (
        text: '„Ich bleibe bei dir.“',
        feedback:
            'Deine Nähe kann Mira guttun. Manchmal möchte man zuerst kurz traurig sein.'
      ),
    ]
  ),
  (
    title: 'Die neue Schaukel',
    story:
        'Noah steht vor der hohen Schaukel. „Ich möchte schauen, wie du das machst.“',
    prompt: 'Was passt zu Noahs Wunsch?',
    choices: [
      (
        text: 'Ich schubse ihn gleich an.',
        feedback:
            'Anschubsen kann überraschen. Noah hat gesagt, dass er zuerst zuschauen möchte.'
      ),
      (
        text: 'Ich schaukle einmal langsam vor.',
        feedback:
            'So sieht Noah den Ablauf. Er entscheidet selbst, wann er dran sein möchte.'
      ),
      (
        text: 'Ich schaue mit ihm den anderen zu.',
        feedback:
            'Ihr könnt gemeinsam zuschauen. Noah bekommt Zeit, sich mit der Schaukel vertraut zu machen.'
      ),
    ]
  ),
  (
    title: 'Zwei Hände, ein Stift',
    story:
        'Du und Lumo wollt den blauen Stift. Du merkst, dass du wütend wirst.',
    prompt: 'Was könntest du als Nächstes tun?',
    choices: [
      (
        text: 'Ich atme aus und bitte um den Stift.',
        feedback:
            'Die kleine Pause gibt dir Zeit für deine Worte. Jetzt kann Lumo dir antworten.'
      ),
      (
        text: 'Wir wechseln uns beim Malen ab.',
        feedback:
            'Mit einem Wechsel bekommt ihr beide Zeit zum Malen. Vereinbart, wer beginnt.'
      ),
      (
        text: 'Ich ziehe am Stift.',
        feedback:
            'Beim Ziehen kann der Stift wegrutschen. Sag Lumo, dass du ihn auch verwenden möchtest.'
      ),
    ]
  ),
  (
    title: 'Ein Platz am Tisch',
    story:
        'Lina sitzt beim Jausnen allein. Du weißt noch nicht, ob sie Gesellschaft möchte.',
    prompt: 'Wie findest du das heraus?',
    choices: [
      (
        text: 'Ich sage allen, Lina sei traurig.',
        feedback:
            'Allein sitzen kann viele Gründe haben. Lina selbst kann sagen, wie es ihr geht.'
      ),
      (
        text: '„Darf ich mich zu dir setzen?“',
        feedback:
            'Deine Frage lässt Lina die Wahl. Auch ein Nein ist in Ordnung.'
      ),
      (
        text: '„Magst du heute lieber Ruhe?“',
        feedback:
            'Du zeigst, dass beides in Ordnung ist. Warte auf Linas Antwort.'
      ),
    ]
  ),
];

const _later = <EmotionScene>[
  (
    title: 'Nach dem Staffellauf',
    story:
        'Euer Team jubelt über Platz zwei. Jona sagt leise: „Ich hätte den Stab gern sicherer übergeben.“',
    prompt: 'Wie reagierst du auf die beiden Blickwinkel?',
    choices: [
      (
        text: '„Wir freuen uns. Und was beschäftigt dich?“',
        feedback:
            'Du gibst der Freude des Teams und Jonas Enttäuschung gleichzeitig Platz.'
      ),
      (
        text: '„Bei Platz zwei musst du doch froh sein!“',
        feedback:
            'Das Team darf sich freuen. Jona darf über die eigene Übergabe trotzdem enttäuscht sein.'
      ),
      (
        text: '„Willst du später mit mir die Übergabe üben?“',
        feedback:
            'Du greifst Jonas konkretes Anliegen auf. Jona entscheidet, ob und wann Üben passt.'
      ),
    ]
  ),
  (
    title: 'Die leise Idee',
    story:
        'Beim Planen sagt Aylin: „Ich habe auch eine Idee.“ Zwei Kinder reden weiter. Aylin legt ihre Skizze weg.',
    prompt: 'Wie kannst du ihr Raum geben?',
    choices: [
      (
        text: 'Ich erkläre ihre Zeichnung für sie.',
        feedback:
            'Deine Deutung könnte anders sein als Aylins Idee. Frag, ob sie selbst erzählen oder Hilfe haben möchte.'
      ),
      (
        text: '„Aylin, möchtest du deine Idee zeigen?“',
        feedback: 'Du machst ihre Idee sichtbar und lässt ihr die Entscheidung.'
      ),
      (
        text: 'Ich schlage eine kurze Ideenrunde vor.',
        feedback:
            'Eine Runde gibt allen Zeit zum Sprechen. Wer möchte, darf auch passen.'
      ),
    ]
  ),
  (
    title: 'Der vergessene Treffpunkt',
    story:
        'Du hast lange auf Ben gewartet. Später sagt Ben: „Ich dachte, wir treffen uns bei der Bücherei.“',
    prompt: 'Was hilft euch bei der Klärung?',
    choices: [
      (
        text: '„Ich war enttäuscht. Wo hast du gewartet?“',
        feedback:
            'Du benennst dein Gefühl und fragst nach Bens Sicht. Beides hilft, das Missverständnis zu klären.'
      ),
      (
        text: 'Wir zeichnen den nächsten Treffpunkt ein.',
        feedback:
            'Eine gemeinsame Markierung hilft beim nächsten Treffen. Ihr könnt euch auch erzählen, wie das Warten war.'
      ),
      (
        text: '„Du wolltest sicher gar nicht kommen.“',
        feedback:
            'Du weißt noch nicht, was Ben vorhatte. Eine Frage gibt dir mehr Hinweise als eine Vermutung.'
      ),
    ]
  ),
  (
    title: 'Das Foto vom Fest',
    story:
        'Euer Gruppenfoto ist schön geworden. Kim sagt: „Ich mag nicht, dass mein Bild am Gang hängt.“',
    prompt: 'Was berücksichtigt Kims Grenze?',
    choices: [
      (
        text: 'Wir stimmen ab, ob es trotzdem hängt.',
        feedback:
            'Über das eigene Bild darf Kim mitentscheiden. Eine Mehrheit ersetzt diese Zustimmung nicht.'
      ),
      (
        text: 'Wir wählen gemeinsam ein anderes Bild.',
        feedback:
            'So kann die Gruppe das Fest zeigen und Kims Wunsch respektieren.'
      ),
      (
        text: 'Ich frage Kim nach einer passenden Lösung.',
        feedback:
            'Mit der Frage gibst du Kim das Wort. Auch der Wunsch, gar kein Bild zu zeigen, gilt.'
      ),
    ]
  ),
];
