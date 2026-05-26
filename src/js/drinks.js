/*
 * ACDB (Aristocats Cocktail Database) — front-end search.
 *
 * Lazy-loads /drinks.json on first switch to body.drinks-view, builds a
 * lowercased searchable string per drink + a base-liquor index by walking
 * the ingredient parent chain, then re-renders on any input/filter change.
 *
 * No external dependencies. Vanilla, written defensively for older browsers
 * that this site already supports (no optional chaining, no spread).
 */
(function () {
    'use strict';

    var SPIRIT_ROOT = 'i:spirit';

    var STATE = {
        loaded: false,
        loading: false,
        drinks: [],                // augmented with _search and _baseLiquors
        ingredientsById: {},       // id -> ingredient metadata
        baseLiquorOptions: [],     // [{id, name}] direct children of i:spirit, used in drinks
        flavorOptions: [],         // sorted unique flavor tags
        selectedBaseLiquors: {},   // id -> true
        selectedFlavors: {},       // tag -> true
        // Has the user interacted at all in this session? On first load with
        // no URL params we show a CTA instead of the full 479-card wall.
        // Once true (filter checked, search typed, "See all" clicked, or URL
        // arrived with params), stays true — clearing filters does NOT bring
        // the intro back.
        hasEngaged: false
    };

    // ----- init / lazy load -----

    function init() {
        var input = document.getElementById('drink-search-input');
        if (input) {
            input.addEventListener('input', onSearchInput);
        }

        // Delegated click handler for the results area:
        //   .drink-reset-all  — clear all filters from the empty-state message
        //   .drink-see-all    — dismiss the intro CTA and show the full list
        //   .drink-report-btn — open the report-issue dialog for that card
        var results = document.getElementById('drink-search-results');
        if (results) {
            results.addEventListener('click', function (ev) {
                var t = ev.target;
                if (!t) return;
                if (t.classList.contains('drink-reset-all')) {
                    ev.preventDefault();
                    clearAll();
                } else if (t.classList.contains('drink-see-all')) {
                    ev.preventDefault();
                    STATE.hasEngaged = true;
                    rerender();
                }
                // The report button uses an <i> child for the icon, so the
                // click target may be either the button or the icon. Walk up
                // to the nearest button to find the data-* attributes.
                var btn = t.closest && t.closest('.drink-report-btn');
                if (btn) {
                    ev.preventDefault();
                    openReportDialog(btn.getAttribute('data-id'), btn.getAttribute('data-name'));
                }
            });
        }

        wireReportDialog();

        if (document.body.classList.contains('drinks-view')) {
            loadData();
        } else {
            // Watch for the ACDB toggle flipping body.drinks-view on.
            var observer = new MutationObserver(function () {
                if (document.body.classList.contains('drinks-view') &&
                    !STATE.loaded && !STATE.loading) {
                    loadData();
                }
            });
            observer.observe(document.body, {
                attributes: true,
                attributeFilter: ['class']
            });
        }
    }

    function loadData() {
        STATE.loading = true;
        renderLoading();
        fetch('/drinks.json')
            .then(function (r) {
                if (!r.ok) throw new Error('HTTP ' + r.status);
                return r.json();
            })
            .then(function (data) {
                ingest(data);
                STATE.loaded = true;
                STATE.loading = false;
                renderFilters();
                syncStateFromURL();   // restore filters/search from ?q=&base=&flavor=
                rerender();           // populates initial dynamic counts as a side-effect
            })
            .catch(function (err) {
                STATE.loading = false;
                console.error('Failed to load drinks.json', err);
                renderError(err);
            });
    }

    function ingest(data) {
        var drinks = data.drinks || [];
        var ingredients = data.ingredients || [];

        // Index ingredients by id.
        var byId = {};
        for (var i = 0; i < ingredients.length; i++) {
            byId[ingredients[i].id] = ingredients[i];
        }
        STATE.ingredientsById = byId;

        // Precompute, per drink:
        //   _search       — lowercased blob of every text field worth matching
        //   _baseLiquors  — set of "base liquor" ingredient ids
        var baseLiquorUsage = {};   // id -> count, so we only show real options
        var flavorSet = {};

        for (var j = 0; j < drinks.length; j++) {
            var d = drinks[j];
            var searchParts = [
                d.name || '',
                d.method || '',
                d.glass || '',
                d.garnish || '',
                d.instructions || '',
                (d.flavor_tags || []).join(' ')
            ];

            var bases = {};
            var drinkIngs = d.ingredients || [];
            for (var k = 0; k < drinkIngs.length; k++) {
                var ingId = drinkIngs[k].id;
                var meta = byId[ingId];
                if (meta) {
                    searchParts.push(meta.name || '');
                    if (meta.aliases) searchParts.push(meta.aliases.join(' '));
                }
                var base = baseLiquorOf(ingId, byId);
                if (base) {
                    bases[base] = true;
                    baseLiquorUsage[base] = (baseLiquorUsage[base] || 0) + 1;
                }
            }
            d._baseLiquors = bases;
            d._search = searchParts.join(' ').toLowerCase();

            var flavors = d.flavor_tags || [];
            for (var f = 0; f < flavors.length; f++) {
                flavorSet[flavors[f]] = true;
            }
        }
        STATE.drinks = drinks;

        // Base liquor options = direct children of i:spirit that actually
        // appear in some drink (so we don't show empty checkboxes).
        var options = [];
        for (var id in baseLiquorUsage) {
            if (Object.prototype.hasOwnProperty.call(baseLiquorUsage, id)) {
                var meta2 = byId[id];
                if (meta2) {
                    options.push({ id: id, name: meta2.name, count: baseLiquorUsage[id] });
                }
            }
        }
        options.sort(function (a, b) { return b.count - a.count; });
        STATE.baseLiquorOptions = options;

        // Flavor options = sorted unique tags.
        var flavorList = [];
        for (var t in flavorSet) {
            if (Object.prototype.hasOwnProperty.call(flavorSet, t)) flavorList.push(t);
        }
        flavorList.sort();
        STATE.flavorOptions = flavorList;
    }

    // Walk parent_id up to the direct child of i:spirit. That's the drink's
    // base liquor for an ingredient. "Plymouth Gin" → "London Dry Gin" → "Gin".
    function baseLiquorOf(ingredientId, byId) {
        var curr = byId[ingredientId];
        if (!curr) return null;
        var hops = 0;
        while (curr && hops < 10) {
            if (curr.parent_id === SPIRIT_ROOT) return curr.id;
            if (!curr.parent_id) return null;
            curr = byId[curr.parent_id];
            hops++;
        }
        return null;
    }

    // ----- filtering / rendering -----

    function onSearchInput() {
        if (!STATE.loaded) return;
        rerender();
    }

    function rerender() {
        var input = document.getElementById('drink-search-input');
        var query = input ? input.value : '';
        // Any active filter or search counts as "engagement" — flip the latch.
        if (hasAnyActiveFilter(query)) STATE.hasEngaged = true;
        renderResults(applyFilters(query));
        updateFilterCounts(query);
        updateClearLinks();
        pushStateToURL(query);
    }

    function hasAnyActiveFilter(query) {
        if (query && query.trim().length > 0) return true;
        if (keys(STATE.selectedBaseLiquors).length > 0) return true;
        if (keys(STATE.selectedFlavors).length > 0) return true;
        return false;
    }

    /* Mirror the current search + filter state into the URL query string so
     * a refresh keeps it and shareable links work. history.replaceState
     * avoids spamming the back-button stack on every keystroke. */
    function pushStateToURL(query) {
        if (typeof URLSearchParams === 'undefined' || !window.history || !history.replaceState) return;
        var params = new URLSearchParams();
        var q = (query || '').trim();
        if (q) params.set('q', q);
        var b = keys(STATE.selectedBaseLiquors);
        if (b.length) params.set('base', b.join(','));
        var f = keys(STATE.selectedFlavors);
        if (f.length) params.set('flavor', f.join(','));
        var qs = params.toString();
        var newUrl = window.location.pathname + (qs ? '?' + qs : '') + window.location.hash;
        history.replaceState(null, '', newUrl);
    }

    /* Read filter state from the URL after data + filter DOM are loaded.
     * Populates STATE, ticks the matching checkboxes, fills the search input. */
    function syncStateFromURL() {
        if (typeof URLSearchParams === 'undefined') return;
        var params = new URLSearchParams(window.location.search);
        var q = params.get('q') || '';
        var bases = (params.get('base') || '').split(',').filter(Boolean);
        var flavors = (params.get('flavor') || '').split(',').filter(Boolean);

        var input = document.getElementById('drink-search-input');
        if (input && q) input.value = q;

        STATE.selectedBaseLiquors = {};
        for (var i = 0; i < bases.length; i++) STATE.selectedBaseLiquors[bases[i]] = true;
        STATE.selectedFlavors = {};
        for (var j = 0; j < flavors.length; j++) STATE.selectedFlavors[flavors[j]] = true;

        var container = document.getElementById('drink-filters');
        if (!container) return;
        var boxes = container.querySelectorAll('input[type="checkbox"]');
        for (var k = 0; k < boxes.length; k++) {
            var kind = boxes[k].getAttribute('data-kind');
            var val = boxes[k].value;
            boxes[k].checked = !!(kind === 'base'
                ? STATE.selectedBaseLiquors[val]
                : STATE.selectedFlavors[val]);
        }
    }

    function applyFilters(query) {
        var q = query.toLowerCase().trim();
        var baseKeys = keys(STATE.selectedBaseLiquors);
        var flavorKeys = keys(STATE.selectedFlavors);
        return STATE.drinks.filter(matcher(q, baseKeys, flavorKeys));
    }

    /* Returns a predicate that says whether a drink matches a given filter set.
     * Shared by applyFilters (one shot for the result list) and
     * updateFilterCounts (called once per filter option to compute its count). */
    function matcher(q, baseFilters, flavorFilters) {
        return function (d) {
            if (q && d._search.indexOf(q) === -1) return false;
            // Base liquor: AND — drink must contain every base in this set.
            for (var i = 0; i < baseFilters.length; i++) {
                if (!d._baseLiquors[baseFilters[i]]) return false;
            }
            // Flavor: AND — drink must carry every flavor in this set.
            var ft = d.flavor_tags || [];
            for (var j = 0; j < flavorFilters.length; j++) {
                if (ft.indexOf(flavorFilters[j]) === -1) return false;
            }
            return true;
        };
    }

    function countMatching(q, baseFilters, flavorFilters) {
        var n = 0;
        var ok = matcher(q, baseFilters, flavorFilters);
        for (var i = 0; i < STATE.drinks.length; i++) {
            if (ok(STATE.drinks[i])) n++;
        }
        return n;
    }

    /* Recompute the "(N)" count on every filter option based on the current
     * filter state, then update the spans in place (preserves checkbox state
     * and the existing event listeners). Each option's count answers:
     *   "If this option were toggled on top of what's already checked, how
     *    many drinks would match?"
     * For already-checked options this equals the current result count;
     * for unchecked options it shows the would-be intersection. Same semantics
     * for base liquor and flavor categories. */
    function updateFilterCounts(query) {
        var q = (query || '').toLowerCase().trim();
        var baseKeys = keys(STATE.selectedBaseLiquors);
        var flavorKeys = keys(STATE.selectedFlavors);

        var container = document.getElementById('drink-filters');
        if (!container) return;

        // Base counts: for each option, try adding it to baseKeys (no-op if already there).
        for (var i = 0; i < STATE.baseLiquorOptions.length; i++) {
            var o = STATE.baseLiquorOptions[i];
            var trial = STATE.selectedBaseLiquors[o.id]
                ? baseKeys
                : baseKeys.concat([o.id]);
            var n = countMatching(q, trial, flavorKeys);
            _setCount(container, 'base', o.id, n);
        }
        // Flavor counts: same pattern.
        for (var j = 0; j < STATE.flavorOptions.length; j++) {
            var f = STATE.flavorOptions[j];
            var trialF = STATE.selectedFlavors[f]
                ? flavorKeys
                : flavorKeys.concat([f]);
            var n2 = countMatching(q, baseKeys, trialF);
            _setCount(container, 'flavor', f, n2);
        }
    }

    function _setCount(container, kind, value, n) {
        var sel = 'input[data-kind="' + kind + '"][value="' + cssEscape(value) + '"]';
        var input = container.querySelector(sel);
        if (!input) return;
        var label = input.parentNode;
        var span = label && label.querySelector('.opt-count');
        if (!span) return;
        span.textContent = '(' + n + ')';
        // Visual cue: dim the option when this filter would zero-out results
        // (and isn't already checked).
        label.classList.toggle('drink-filter-option--empty', n === 0 && !input.checked);
    }

    /* Minimal CSS.escape polyfill — values like "i:gin" need the colon escaped
     * inside attribute selectors. */
    function cssEscape(s) {
        return String(s).replace(/[^a-zA-Z0-9_-]/g, function (c) {
            return '\\' + c;
        });
    }

    function renderFilters() {
        var container = document.getElementById('drink-filters');
        if (!container) return;
        var html = '';
        if (STATE.baseLiquorOptions.length) {
            html += '<div class="drink-filter-row">';
            html += '<div class="drink-filter-side">';
            html += '<div class="drink-filter-label">Base:</div>';
            html += '<a class="drink-filter-clear" data-kind="base" href="#" hidden>✕ clear</a>';
            html += '</div>';
            html += '<span class="drink-filter-chips">';
            for (var i = 0; i < STATE.baseLiquorOptions.length; i++) {
                var o = STATE.baseLiquorOptions[i];
                html += '<label class="drink-filter-option">' +
                    '<input type="checkbox" data-kind="base" value="' + escapeAttr(o.id) + '"> ' +
                    escapeHtml(o.name) + ' <span class="opt-count">(' + o.count + ')</span>' +
                    '</label>';
            }
            html += '</span></div>';
        }
        if (STATE.flavorOptions.length) {
            html += '<div class="drink-filter-row">';
            html += '<div class="drink-filter-side">';
            html += '<div class="drink-filter-label">Flavor:</div>';
            html += '<a class="drink-filter-clear" data-kind="flavor" href="#" hidden>✕ clear</a>';
            html += '</div>';
            html += '<span class="drink-filter-chips">';
            for (var k = 0; k < STATE.flavorOptions.length; k++) {
                var f = STATE.flavorOptions[k];
                html += '<label class="drink-filter-option">' +
                    '<input type="checkbox" data-kind="flavor" value="' + escapeAttr(f) + '"> ' +
                    escapeHtml(f) + ' <span class="opt-count">(0)</span>' +
                    '</label>';
            }
            html += '</span></div>';
        }
        container.innerHTML = html;

        // Delegate checkbox changes.
        container.addEventListener('change', function (ev) {
            var t = ev.target;
            if (!t || t.tagName !== 'INPUT' || t.type !== 'checkbox') return;
            var bag = t.getAttribute('data-kind') === 'base'
                ? STATE.selectedBaseLiquors : STATE.selectedFlavors;
            if (t.checked) bag[t.value] = true;
            else delete bag[t.value];
            rerender();
        });

        // Delegate "clear" link clicks. Each link wipes only its own category.
        container.addEventListener('click', function (ev) {
            var t = ev.target;
            if (!t || !t.classList.contains('drink-filter-clear')) return;
            ev.preventDefault();
            clearCategory(t.getAttribute('data-kind'));
        });
    }

    function clearCategory(kind) {
        if (kind === 'base') STATE.selectedBaseLiquors = {};
        else if (kind === 'flavor') STATE.selectedFlavors = {};
        else return;
        var container = document.getElementById('drink-filters');
        if (container) {
            var boxes = container.querySelectorAll('input[data-kind="' + kind + '"]');
            for (var i = 0; i < boxes.length; i++) boxes[i].checked = false;
        }
        rerender();
    }

    function clearAll() {
        STATE.selectedBaseLiquors = {};
        STATE.selectedFlavors = {};
        var input = document.getElementById('drink-search-input');
        if (input) input.value = '';
        var container = document.getElementById('drink-filters');
        if (container) {
            var boxes = container.querySelectorAll('input[type="checkbox"]');
            for (var i = 0; i < boxes.length; i++) boxes[i].checked = false;
        }
        rerender();
    }

    /* Show or hide the per-category clear links based on whether anything is
     * currently selected in that category. */
    function updateClearLinks() {
        var container = document.getElementById('drink-filters');
        if (!container) return;
        var baseHas = keys(STATE.selectedBaseLiquors).length > 0;
        var flavorHas = keys(STATE.selectedFlavors).length > 0;
        var b = container.querySelector('.drink-filter-clear[data-kind="base"]');
        var f = container.querySelector('.drink-filter-clear[data-kind="flavor"]');
        if (b) b.hidden = !baseHas;
        if (f) f.hidden = !flavorHas;
    }

    function renderResults(results) {
        var container = document.getElementById('drink-search-results');
        if (!container) return;
        var sorted = sortDrinks(results);
        var total = STATE.drinks.length;
        var filtered = sorted.length;

        // Intro state: show a CTA instead of the full card list until the user
        // has engaged once. Removing all filters later does NOT bring this
        // state back — the latch is one-way in `rerender()`.
        var input = document.getElementById('drink-search-input');
        var query = input ? input.value : '';
        if (!STATE.hasEngaged && !hasAnyActiveFilter(query)) {
            container.innerHTML = '<div class="drink-intro">' +
                '<p>Browse <strong>' + total + '</strong> cocktails, or filter above to narrow down.</p>' +
                '<a class="drink-see-all" href="#">See all drinks</a>' +
                '</div>';
            return;
        }

        if (!filtered) {
            // Empty state — if it's because of filters, offer a way out.
            var hasFilters =
                keys(STATE.selectedBaseLiquors).length > 0 ||
                keys(STATE.selectedFlavors).length > 0 ||
                (document.getElementById('drink-search-input') || {}).value;
            container.innerHTML = '<div class="drink-empty">' +
                '<p>No drinks matched.</p>' +
                (hasFilters ? '<a class="drink-reset-all" href="#">Clear all filters</a>' : '') +
                '</div>';
            return;
        }

        // "X drinks" when nothing is filtered, "X of N drinks" otherwise.
        var countText = (filtered === total)
            ? (filtered + ' drinks')
            : (filtered + ' of ' + total + ' drinks');

        var html = '<div class="drink-count">' + countText + '</div>';
        for (var i = 0; i < sorted.length; i++) {
            html += renderCard(sorted[i]);
        }
        container.innerHTML = html;
    }

    function sortDrinks(drinks) {
        return drinks.slice().sort(function (a, b) {
            var pa = a.popularity || 1, pb = b.popularity || 1;
            if (pa !== pb) return pb - pa;     // popularity desc
            return a.name.localeCompare(b.name);
        });
    }

    function renderCard(d) {
        // Title-line tier pill. Popularity is rendered as a neutral text pill
        // (not stars — stars read as a quality rating, which this isn't).
        // Three tiers: Classic (3), Familiar (2), Niche (1, the long tail).
        var tierBadge = '';
        if (d.popularity === 3) {
            tierBadge = ' <span class="drink-tier tier-3">Classic</span>';
        } else if (d.popularity === 2) {
            tierBadge = ' <span class="drink-tier tier-2">Familiar</span>';
        } else {
            tierBadge = ' <span class="drink-tier tier-1">Niche</span>';
        }

        // ACATS-approved drinks get the banner cat silhouette pinned to the
        // far left of the card header, recolored to the site's primary green
        // via CSS mask. No badge text — the cat alone is the signal.
        var acatsCat = d.acats_approved
            ? '<span class="acats-cat" title="Aristocats recommends"></span>'
            : '';

        // Report-issue flag. Outline FA flag intentionally — solid reads too
        // close to a "favorite" affordance. Tooltip + aria-label disambiguate.
        var reportBtn =
            '<button type="button" class="drink-report-btn" ' +
                'data-id="' + escapeAttr(d.id) + '" ' +
                'data-name="' + escapeAttr(d.name) + '" ' +
                'aria-label="Report an issue with this recipe" ' +
                'title="Report an issue with this recipe">' +
                '<i class="fa-regular fa-flag" aria-hidden="true"></i>' +
            '</button>';

        var ingHtml = '';
        var ings = d.ingredients || [];
        if (ings.length) {
            var parts = '';
            for (var i = 0; i < ings.length; i++) {
                var ing = ings[i];
                var meta = STATE.ingredientsById[ing.id];
                var name = meta ? meta.name : ing.id;
                parts += '<li>' +
                    '<span class="ing-amount">' + formatAmount(ing) + '</span> ' +
                    '<span class="ing-name">' + escapeHtml(name) + '</span>' +
                    (ing.note ? ' <span class="ing-note">' + escapeHtml(ing.note) + '</span>' : '') +
                    '</li>';
            }
            ingHtml = '<ul class="drink-ingredients">' + parts + '</ul>';
        }

        var metaParts = [];
        if (d.glass) metaParts.push('<span class="meta-glass">' + escapeHtml(d.glass) + ' glass</span>');
        if (d.method) metaParts.push('<span class="meta-method">' + escapeHtml(d.method) + '</span>');
        var metaRow = metaParts.length ? '<div class="drink-meta">' + metaParts.join(' · ') + '</div>' : '';

        var flavorRow = '';
        if (d.flavor_tags && d.flavor_tags.length) {
            var ft = '';
            for (var j = 0; j < d.flavor_tags.length; j++) {
                ft += '<span class="flavor-tag">' + escapeHtml(d.flavor_tags[j]) + '</span>';
            }
            flavorRow = '<div class="drink-flavors">' + ft + '</div>';
        }

        return '<article class="drink-card">' +
            '<div class="drink-card-header">' +
                '<h3 class="drink-name">' + escapeHtml(d.name) + tierBadge + '</h3>' +
                acatsCat +
            '</div>' +
            metaRow +
            ingHtml +
            (d.instructions ? '<p class="drink-instructions">' + formatProse(d.instructions) + '</p>' : '') +
            (d.garnish ? '<p class="drink-garnish"><em>Garnish:</em> ' + formatProse(d.garnish) + '</p>' : '') +
            flavorRow +
            '<div class="drink-card-footer">' + reportBtn + '</div>' +
            '</article>';
    }

    /* Escape and insert <br> after each sentence-ending period followed by a
     * capital letter. Guards against splitting "1.5 oz" or "e.g." mid-text;
     * only intersentence breaks match the pattern. */
    function formatProse(text) {
        if (!text) return '';
        return escapeHtml(text).replace(/\. (?=[A-Z])/g, '.<br>');
    }

    function formatAmount(ing) {
        if (ing.amount == null) {
            if (ing.unit === 'to_taste') return '<em>to taste</em>';
            if (ing.unit === 'ml') return '<em>splash</em>';
            return '';
        }
        if (ing.unit === 'ml') return ing.amount + ' ml';
        if (ing.unit === 'g') return ing.amount + ' g';
        return ing.amount + ' ' + ing.unit + (ing.amount === 1 ? '' : 's');
    }

    function renderLoading() {
        var c = document.getElementById('drink-search-results');
        if (c) c.innerHTML = '<div class="drink-loading">Loading drinks…</div>';
    }

    function renderError(err) {
        var c = document.getElementById('drink-search-results');
        if (c) c.innerHTML = '<div class="drink-error">Could not load drinks: ' +
            escapeHtml(String(err && err.message || err)) + '</div>';
    }

    // ----- report-issue dialog -----

    // Minimum length to discourage "asdf"-style empty submissions. Anything
    // shorter is almost certainly noise, not actionable feedback.
    var REPORT_MIN_LEN = 10;

    function wireReportDialog() {
        var dlg = document.getElementById('drink-report-dialog');
        if (!dlg) return;
        var form = dlg.querySelector('form');
        var cancel = dlg.querySelector('.drink-report-cancel');

        if (form) {
            form.addEventListener('submit', function (ev) {
                ev.preventDefault();
                submitReport(dlg);
            });
        }
        if (cancel) {
            cancel.addEventListener('click', function () {
                dlg.close();
            });
        }
    }

    function openReportDialog(drinkId, drinkName) {
        var dlg = document.getElementById('drink-report-dialog');
        if (!dlg || typeof dlg.showModal !== 'function') return;

        dlg.querySelector('.drink-report-drink-name').textContent = drinkName || '';
        dlg.setAttribute('data-drink-id', drinkId || '');
        dlg.setAttribute('data-drink-name', drinkName || '');

        var ta = dlg.querySelector('textarea');
        if (ta) {
            ta.value = '';
            ta.classList.remove('invalid');
        }
        var status = dlg.querySelector('.drink-report-status');
        if (status) status.textContent = '';
        dlg.showModal();
        if (ta) ta.focus();
    }

    function submitReport(dlg) {
        var ta = dlg.querySelector('textarea');
        var status = dlg.querySelector('.drink-report-status');
        var feedback = (ta && ta.value || '').trim();

        if (feedback.length < REPORT_MIN_LEN) {
            ta.classList.add('invalid');
            status.textContent = 'Please add at least ' + REPORT_MIN_LEN + ' characters of detail.';
            return;
        }

        var drinkId = dlg.getAttribute('data-drink-id') || '';
        var drinkName = dlg.getAttribute('data-drink-name') || '';

        if (typeof window.emit === 'function') {
            try {
                window.emit('drink_feedback', {
                    drink_id: drinkId,
                    drink_name: drinkName,
                    feedback: feedback
                });
            } catch (e) { /* swallow — UX shouldn't fail if analytics does */ }
        }

        status.textContent = 'Thanks — your feedback was sent.';
        ta.classList.remove('invalid');
        // Brief delay so the user sees the confirmation before the dialog
        // disappears. 1500 ms keeps the success message visible long enough
        // to read comfortably without feeling stuck.
        setTimeout(function () { dlg.close(); }, 1500);
    }

    // ----- tiny utils -----

    function keys(obj) {
        var out = [];
        for (var k in obj) {
            if (Object.prototype.hasOwnProperty.call(obj, k)) out.push(k);
        }
        return out;
    }

    function escapeHtml(s) {
        return String(s).replace(/[&<>"']/g, function (c) {
            return { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c];
        });
    }
    function escapeAttr(s) {
        return escapeHtml(s);
    }

    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', init);
    } else {
        init();
    }
})();
