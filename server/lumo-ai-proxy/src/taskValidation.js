// Numerical tasks carry a calculation that is checked independently of the model.
function checkedSteps(calculation, grade) {
  if (!Number.isInteger(grade) || grade < 1 || grade > 4) return null;
  if (!calculation || !Array.isArray(calculation.steps) || !calculation.steps.length || calculation.steps.length > 3) return null;
  const limit = [0, 20, 100, 1000, 10000][grade];
  const checked = [];
  let value;
  for (const step of calculation.steps) {
    if (!step || typeof step !== 'object' || (checked.length && step.a !== 'previous')) return null;
    const a = step.a === 'previous' ? value : step.a;
    const b = step.b;
    if (!Number.isInteger(a) || !Number.isInteger(b) || a < 0 || b < 0 || a > limit || b > limit) return null;
    switch (step.op) {
      case 'add': value = a + b; break;
      case 'subtract': value = a - b; break;
      case 'multiply': if (grade < 2) return null; value = a * b; break;
      case 'divide': if (grade < 2 || b === 0 || a % b) return null; value = a / b; break;
      default: return null;
    }
    if (value < 0 || value > limit) return null;
    checked.push({ a, b, op: step.op, value });
  }
  return checked;
}

export function validateCalculation(calculation, answer, grade) {
  const steps = checkedSteps(calculation, grade);
  return Boolean(steps && String(steps.at(-1).value) === String(answer).trim());
}

// Free-form stories cannot be verified by arithmetic metadata alone. Display
// the checked operations themselves so prompt, explanation and answer agree.
export function buildCalculationTask(calculation, answer, grade) {
  const steps = checkedSteps(calculation, grade);
  if (!steps || String(steps.at(-1).value) !== String(answer).trim()) return null;
  const symbols = { add: '+', subtract: '-', multiply: '×', divide: '÷' };
  const instructions = {
    add: (b) => `Zähle ${b} dazu.`,
    subtract: (b) => `Ziehe ${b} ab.`,
    multiply: (b) => `Nimm das Ergebnis mal ${b}.`,
    divide: (b) => `Teile das Ergebnis durch ${b}.`,
  };
  const first = steps[0];
  const prompt = steps.length === 1
    ? `Rechne: ${first.a} ${symbols[first.op]} ${first.b} = ?`
    : `Starte mit ${first.a}. ${steps.map((step) => instructions[step.op](step.b)).join(' ')} Welche Zahl erhältst du?`;
  const explanation = steps.map((step) => `${step.a} ${symbols[step.op]} ${step.b} = ${step.value}.`).join(' ');
  return { prompt, explanation };
}

export function normalizePrompt(value) {
  return String(value).normalize('NFKC').toLocaleLowerCase('de-AT').replace(/\s+/g, ' ').trim();
}
