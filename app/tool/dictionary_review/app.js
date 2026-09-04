const pageSize = 50;
let source = [];
let decisions = {};
let filtered = [];
let page = 0;
const selected = new Set();
const $ = (id) => document.getElementById(id);

async function load() {
  const response = await fetch('/api/candidates');
  const data = await response.json();
  source = data.candidates;
  decisions = data.decisions;
  applyFilters();
}

function decisionFor(candidate) {
  return decisions[candidate.internalId]?.decision || (candidate.currentlyActiveAnswer ? 'approve' : 'pending');
}

function applyFilters() {
  const query = $('search').value.trim().toUpperCase();
  const decision = $('decision-filter').value;
  const priority = $('priority-filter').value;
  const origin = $('source-filter').value;
  const language = $('language-filter').value;
  const length = $('length-filter').value;
  filtered = source.filter((candidate) => {
    if (query && !candidate.word.toUpperCase().includes(query) && !String(candidate.displayWord || '').toUpperCase().includes(query) && !candidate.definition.toUpperCase().includes(query)) return false;
    if (decision !== 'all' && decisionFor(candidate) !== decision) return false;
    if (priority !== 'all' && candidate.recommendation !== priority) return false;
    if (origin === 'existing' && !candidate.currentlyInApp) return false;
    if (origin === 'missing' && candidate.currentlyInApp) return false;
    if (language !== 'all' && candidate.language !== language) return false;
    if (length !== 'all' && String(candidate.length) !== length) return false;
    return true;
  });
  const sort = $('sort').value;
  filtered.sort((a,b) => sort === 'word' ? a.word.localeCompare(b.word) : sort === 'frequency' ? (b.zipfFrequency || 0) - (a.zipfFrequency || 0) : a.rank - b.rank);
  page = Math.min(page, Math.max(0, Math.ceil(filtered.length / pageSize) - 1));
  render();
}

function render() {
  renderStats();
  const list = $('candidate-list');
  list.replaceChildren();
  const items = filtered.slice(page * pageSize, (page + 1) * pageSize);
  if (!items.length) list.innerHTML = '<p class="empty">No candidates match these filters.</p>';
  for (const candidate of items) list.append(renderCandidate(candidate));
  const pages = Math.max(1, Math.ceil(filtered.length / pageSize));
  $('page-label').textContent = `Page ${page + 1} of ${pages} · ${filtered.length} words`;
  $('previous').disabled = page === 0;
  $('next').disabled = page + 1 >= pages;
  $('select-page').checked = items.length > 0 && items.every((item) => selected.has(item.internalId));
  $('selected-count').textContent = `${selected.size} selected`;
}

function renderStats() {
  const counts = {pending:0,approve:0,guess_only:0,reject:0};
  for (const candidate of source) counts[decisionFor(candidate)]++;
  $('stats').innerHTML = [['Total',source.length],['Pending',counts.pending],['Approved',counts.approve],['Guess only',counts.guess_only],['Rejected',counts.reject]].map(([label,value]) => `<div class="stat"><strong>${value}</strong><span>${label}</span></div>`).join('');
}

function renderCandidate(candidate) {
  const node = $('candidate-template').content.firstElementChild.cloneNode(true);
  const saved = decisions[candidate.internalId] || {};
  const currentDecision = decisionFor(candidate);
  node.dataset.word = candidate.word;
  node.dataset.id = candidate.internalId;
  node.dataset.decision = currentDecision;
  node.querySelector('.word').textContent = candidate.displayWord || candidate.word;
  const languageLabel = candidate.language === 'gurmukhi' ? 'Gurmukhi' : candidate.language === 'romanized_panjabi' ? 'Romanized Panjabi' : 'English';
  node.querySelector('.meta').textContent = `${languageLabel} · ${candidate.length} letters${candidate.gurmukhiLength ? ` · Gurmukhi ${candidate.gurmukhiLength}` : ''} · ${candidate.currentlyInApp ? 'in app' : 'missing'}`;
  node.querySelector('.decision-badge').textContent = currentDecision.replace('_',' ');
  node.querySelector('.definition').value = saved.definition || candidate.definition || '';
  node.querySelector('.notes').value = saved.notes || '';
  const checkbox = node.querySelector('.select-candidate');
  checkbox.checked = selected.has(candidate.internalId);
  checkbox.addEventListener('change', () => { checkbox.checked ? selected.add(candidate.internalId) : selected.delete(candidate.internalId); render(); });
  for (const button of node.querySelectorAll('[data-decision]')) button.addEventListener('click', () => saveCandidate(node, button.dataset.decision));
  return node;
}

async function saveCandidate(node, decision) {
  const candidate = source.find((item) => item.internalId === node.dataset.id);
  const update = {id:node.dataset.id, word:candidate.word, language:candidate.language, length:candidate.length, decision, definition:node.querySelector('.definition').value, notes:node.querySelector('.notes').value};
  await save('/api/decision', update);
  decisions[node.dataset.id] = update;
  applyFilters();
}

async function bulk(decision) {
  if (!selected.size) return;
  if (!confirm(`${decision.replace('_',' ')} ${selected.size} selected words?`)) return;
  const entries = [...selected].map((id) => {
    const candidate = source.find((item) => item.internalId === id);
    const saved = decisions[id] || {};
    return {id, word:candidate.word, language:candidate.language, length:candidate.length, decision, definition:saved.definition || candidate.definition || '', notes:saved.notes || ''};
  });
  await save('/api/bulk', {entries});
  for (const entry of entries) decisions[entry.id] = entry;
  selected.clear();
  applyFilters();
}

async function save(url, body) {
  $('save-status').textContent = 'Saving…';
  const response = await fetch(url,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(body)});
  const result = await response.json();
  if (!response.ok) { $('save-status').textContent = result.error || 'Save failed'; throw new Error(result.error); }
  $('save-status').textContent = 'Saved';
}

for (const id of ['search','decision-filter','priority-filter','source-filter','language-filter','length-filter','sort']) $(id).addEventListener(id === 'search' ? 'input' : 'change', applyFilters);
$('previous').addEventListener('click', () => { page--; render(); scrollTo({top:0,behavior:'smooth'}); });
$('next').addEventListener('click', () => { page++; render(); scrollTo({top:0,behavior:'smooth'}); });
$('select-page').addEventListener('change', (event) => { for (const item of filtered.slice(page*pageSize,(page+1)*pageSize)) event.target.checked ? selected.add(item.internalId) : selected.delete(item.internalId); render(); });
for (const button of document.querySelectorAll('[data-bulk]')) button.addEventListener('click', () => bulk(button.dataset.bulk));
load().catch((error) => { $('save-status').textContent = 'Could not load'; console.error(error); });
