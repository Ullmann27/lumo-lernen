// Numerical tasks carry a calculation that is checked independently of the model.
export function validateCalculation(calculation, answer, grade) {
  if (!calculation || !Array.isArray(calculation.steps) || !calculation.steps.length || calculation.steps.length > 3) return false;
  const limit = [0, 20, 100, 1000, 10000][grade];
  let value;
  for (const step of calculation.steps) {
    const a = step.a === 'previous' ? value : step.a;
    const b = step.b;
    if (!Number.isInteger(a) || !Number.isInteger(b) || a < 0 || b < 0 || a > limit || b > limit) return false;
    switch (step.op) {
      case 'add': value = a + b; break;
      case 'subtract': value = a - b; break;
      case 'multiply': if (grade < 2) return false; value = a * b; break;
      case 'divide': if (grade < 2 || b === 0 || a % b) return false; value = a / b; break;
      default: return false;
    }
    if (value < 0 || value > limit) return false;
  }
  return String(value) === String(answer).trim();
}

export function normalizePrompt(value) {
  return String(value).normalize('NFKC').toLocaleLowerCase('de-AT').replace(/\s+/g, ' ').trim();
}
