// Nordvik portal front end. All text is inserted with textContent (never innerHTML)
// so ticket text from tenants cannot inject markup.
(function () {
  "use strict";
  var HEADERS = { "X-Requested-With": "nordvik-portal" };
  var STATUS = { ny: "Ny", pagar: "Pågår", klar: "Klar" };
  var ROLE = { hyresgast: "Hyresgäst", forvaltare: "Förvaltare", ekonomi: "Ekonomi" };
  var me = null;
  var view = document.getElementById("view");
  var tabsEl = document.getElementById("tabs");

  function h(tag, attrs) {
    var e = document.createElement(tag);
    Object.keys(attrs || {}).forEach(function (k) {
      if (k === "text") e.textContent = attrs[k];
      else if (k === "class") e.className = attrs[k];
      else if (k.slice(0, 2) === "on") e.addEventListener(k.slice(2), attrs[k]);
      else e.setAttribute(k, attrs[k]);
    });
    for (var i = 2; i < arguments.length; i++) {
      var c = arguments[i];
      if (c == null) continue;
      e.appendChild(typeof c === "string" ? document.createTextNode(c) : c);
    }
    return e;
  }

  function api(path, opts) {
    opts = opts || {};
    opts.headers = Object.assign({}, HEADERS, opts.headers || {});
    opts.credentials = "same-origin";
    return fetch(path, opts).then(function (r) {
      if (r.status === 401) throw new Error("Du är inte inloggad eller sessionen har gått ut. Ladda om sidan för att logga in igen.");
      return r.json().catch(function () { return {}; }).then(function (body) {
        if (!r.ok) throw new Error(body.fel || "Något gick fel (" + r.status + ").");
        return body;
      });
    });
  }

  function fmtDate(iso) {
    if (!iso) return "";
    var d = new Date(iso);
    return d.toLocaleString("sv-SE", { dateStyle: "short", timeStyle: "short", timeZone: "Europe/Stockholm" });
  }
  function fmtMonth(m) { return m.slice(0, 4) + "-" + m.slice(4, 6); }
  function fmtSize(b) { return b > 1048576 ? (b / 1048576).toFixed(1) + " MB" : Math.max(1, Math.round(b / 1024)) + " kB"; }
  function clear(el) { while (el.firstChild) el.removeChild(el.firstChild); }
  function error(msg) { return h("p", { class: "notice", role: "alert", text: msg }); }

  // ---------- tickets ----------
  function ticketCard(t, manager) {
    var card = h("article", { class: "ticket" + (t.akut ? " akut" : "") });
    var statusChip = h("span", { class: "chip " + t.status, text: STATUS[t.status] || t.status });
    var chips = h("span", null, statusChip);
    if (t.akut) chips.appendChild(h("span", { class: "chip akut", text: "Akut" }));
    card.appendChild(h("div", { class: "ticket-head" },
      h("span", { class: "ticket-title", text: t.rubrik || t.kategoriNamn }), chips));
    var meta = t.kategoriNamn + " · " + fmtDate(t.skapad);
    if (manager) meta += " · " + t.fastighet + ", enhet " + t.enhet + " · " + t.hyresgastNamn;
    card.appendChild(h("div", { class: "meta", text: meta }));
    if (manager && t.hyresgastMail) card.appendChild(h("div", { class: "meta", text: t.hyresgastMail }));
    card.appendChild(h("p", { text: t.beskrivning }));
    if (t.harBild) card.appendChild(h("img", { src: "/api/arenden/" + encodeURIComponent(t.id) + "/bild", alt: "Bifogad bild", loading: "lazy" }));
    if (!manager && t.losning) {
      card.appendChild(h("div", { class: "solution-box" },
        h("strong", { text: "Lösning" + (t.losningTid ? " (" + fmtDate(t.losningTid) + ")" : "") }),
        h("p", { text: t.losning })));
    }
    if (manager) {
      var sel = h("select", { "aria-label": "Status" });
      Object.keys(STATUS).forEach(function (k) {
        var o = h("option", { value: k, text: STATUS[k] }); if (k === t.status) o.selected = true; sel.appendChild(o);
      });
      var ta = h("textarea", { class: "solution", maxlength: "4000", "aria-label": "Lösning",
        placeholder: "Lösning: beskriv vad som har gjorts. Hyresgästen ser texten." });
      ta.value = t.losning || "";
      var msg = h("span", { class: "meta", "aria-live": "polite" });
      var save = h("button", { class: "primary", type: "button", text: "Spara" });
      save.addEventListener("click", function () {
        if (sel.value === "klar" && !ta.value.trim() && !confirm("Markera som klar utan lösning?")) return;
        save.disabled = true; msg.textContent = "";
        api("/api/arenden/" + encodeURIComponent(t.id) + "/status", {
          method: "POST", headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ status: sel.value, losning: ta.value })
        }).then(function (r) {
          statusChip.className = "chip " + r.status; statusChip.textContent = STATUS[r.status] || r.status;
          msg.textContent = "Sparat.";
        }).catch(function (e) { msg.textContent = e.message; })
          .then(function () { save.disabled = false; });
      });
      card.appendChild(h("div", { class: "manage" },
        h("label", { class: "meta" }, "Status ", sel), ta,
        h("div", { class: "row" }, save, msg)));
    }
    return card;
  }

  function showMyTickets(flash) {
    clear(view);
    view.appendChild(h("h1", { text: "Mina ärenden" }));
    view.appendChild(h("p", { class: "lead", text: "Här ser du dina felanmälningar och hur långt de har kommit." }));
    if (flash) view.appendChild(h("p", { class: "ok", role: "status", text: flash }));
    var list = h("div"); view.appendChild(list);
    list.appendChild(h("p", { class: "muted", text: "Laddar…" }));
    api("/api/arenden").then(function (items) {
      clear(list);
      if (!items.length) list.appendChild(h("p", { class: "muted", text: "Du har inga ärenden ännu." }));
      items.forEach(function (t) { list.appendChild(ticketCard(t, false)); });
    }).catch(function (e) { clear(list); list.appendChild(error(e.message)); });
  }

  function showReport() {
    clear(view);
    view.appendChild(h("h1", { text: "Felanmälan" }));
    view.appendChild(h("p", { class: "lead", text: "Beskriv felet så noga du kan. En bild gör det lättare för oss att komma rätt." }));
    view.appendChild(h("p", { class: "notice", text: "Vid brand eller personskada: ring 112. Akuta fel (till exempel vattenläcka eller strömavbrott) går direkt till din förvaltare." }));
    var sel = h("select", { id: "kategori", name: "kategori", required: "required" }, h("option", { value: "", text: "Välj…" }));
    var og1 = h("optgroup", { label: "Akuta fel" }), og2 = h("optgroup", { label: "Övriga fel" });
    me.kategorier.forEach(function (k) { (k.akut ? og1 : og2).appendChild(h("option", { value: k.id, text: k.namn })); });
    sel.appendChild(og1); sel.appendChild(og2);
    var file = h("input", { type: "file", id: "bild", name: "bild", accept: "image/jpeg,image/png,image/webp,image/heic" });
    var preview = h("img", { class: "preview", alt: "Förhandsvisning", hidden: "hidden" });
    file.addEventListener("change", function () {
      var f = file.files[0];
      if (f && f.size > 8 * 1048576) { file.value = ""; preview.hidden = true; alert("Bilden är för stor (max 8 MB)."); return; }
      if (f && f.type !== "image/heic") { preview.src = URL.createObjectURL(f); preview.hidden = false; } else { preview.hidden = true; }
    });
    var msg = h("div", { "aria-live": "polite" });
    var btn = h("button", { class: "primary", type: "submit", text: "Skicka felanmälan" });
    var form = h("form", { class: "card" },
      h("label", null, "Vad gäller det?", sel),
      h("label", null, "Rubrik ", h("small", { text: "Valfritt, en kort rad" }), h("input", { name: "rubrik", maxlength: "120" })),
      h("label", null, "Beskrivning", h("textarea", { name: "beskrivning", required: "required", maxlength: "4000" })),
      h("label", null, "Bild ", h("small", { text: "Valfritt, JPG, PNG eller HEIC, max 8 MB" }), file), preview,
      btn, msg);
    form.addEventListener("submit", function (ev) {
      ev.preventDefault(); btn.disabled = true; clear(msg);
      api("/api/arenden", { method: "POST", body: new FormData(form) }).then(function (r) {
        showMyTickets("Tack! Din felanmälan är skickad" + (r.akut ? " och har gått direkt till din förvaltare." : "."));
      }).catch(function (e) { btn.disabled = false; msg.appendChild(error(e.message)); });
    });
    view.appendChild(form);
  }

  // ---------- manager ----------
  function showManager() {
    clear(view);
    view.appendChild(h("h1", { text: "Ärenden" }));
    var prop = h("select", { id: "f-prop" }, h("option", { value: "", text: "Alla mina fastigheter" }));
    me.fastigheter.forEach(function (p) { prop.appendChild(h("option", { value: p.id, text: p.namn })); });
    var st = h("select", { id: "f-status" }, h("option", { value: "", text: "Alla" }));
    Object.keys(STATUS).forEach(function (k) { st.appendChild(h("option", { value: k, text: STATUS[k] })); });
    var list = h("div");
    function load() {
      clear(list); list.appendChild(h("p", { class: "muted", text: "Laddar…" }));
      var q = "?fastighet=" + encodeURIComponent(prop.value) + "&status=" + encodeURIComponent(st.value);
      api("/api/arenden" + q).then(function (items) {
        clear(list);
        items.sort(function (a, b) { return (b.akut && b.status !== "klar") - (a.akut && a.status !== "klar") || (a.id < b.id ? 1 : -1); });
        if (!items.length) list.appendChild(h("p", { class: "muted", text: "Inga ärenden." }));
        items.forEach(function (t) { list.appendChild(ticketCard(t, true)); });
      }).catch(function (e) { clear(list); list.appendChild(error(e.message)); });
    }
    prop.addEventListener("change", load); st.addEventListener("change", load);
    view.appendChild(h("div", { class: "filters" }, h("label", null, "Fastighet", prop), h("label", null, "Status", st)));
    view.appendChild(list); load();
  }

  // ---------- documents ----------
  function showDocs() {
    clear(view);
    view.appendChild(h("h1", { text: "Dokument" }));
    view.appendChild(h("p", { class: "lead", text: "Hyreskontrakt och besiktningsprotokoll." }));
    var box = h("div");
    var q = "";
    if (me.roll === "forvaltare") {
      var prop = h("select", null, h("option", { value: "", text: "Alla mina fastigheter" }));
      me.fastigheter.forEach(function (p) { prop.appendChild(h("option", { value: p.id, text: p.namn })); });
      var unit = h("input", { placeholder: "Enhet, t.ex. 1204" });
      var go = h("button", { class: "primary", type: "button", text: "Sök" });
      go.addEventListener("click", function () { load("?fastighet=" + encodeURIComponent(prop.value) + "&enhet=" + encodeURIComponent(unit.value.trim())); });
      view.appendChild(h("div", { class: "filters" }, h("label", null, "Fastighet", prop), h("label", null, "Enhet", unit), go));
    }
    view.appendChild(box);
    function load(query) {
      clear(box); box.appendChild(h("p", { class: "muted", text: "Laddar…" }));
      api("/api/dokument" + (query || q)).then(function (docs) {
        clear(box);
        if (!docs.length) { box.appendChild(h("p", { class: "muted", text: "Inga dokument hittades." })); return; }
        var ul = h("ul", { class: "docs" });
        docs.forEach(function (d) {
          ul.appendChild(h("li", null,
            h("a", { href: "/api/dokument/hamta?namn=" + encodeURIComponent(d.namn), text: d.visa }),
            h("span", { class: "meta", text: fmtSize(d.storlek) + " · " + fmtDate(d.andrad) })));
        });
        box.appendChild(ul);
      }).catch(function (e) { clear(box); box.appendChild(error(e.message)); });
    }
    if (me.roll === "hyresgast") load("");
  }

  // ---------- statistics ----------
  function showStats() {
    clear(view);
    view.appendChild(h("h1", { text: "Statistik" }));
    view.appendChild(h("p", { class: "lead", text: "Antal felanmälningar de senaste 12 månaderna. Inga personuppgifter visas." }));
    var box = h("div"); view.appendChild(box); box.appendChild(h("p", { class: "muted", text: "Laddar…" }));
    api("/api/statistik").then(function (s) {
      clear(box);
      function tbl(head, rows, withBar) {
        var max = Math.max.apply(null, rows.map(function (r) { return r[r.length - 1]; }).concat([1]));
        var t = h("table"), tr = h("tr");
        head.forEach(function (x, i) { tr.appendChild(h("th", { class: i ? "num" : "", text: x })); });
        if (withBar) tr.appendChild(h("th", { text: "" }));
        t.appendChild(h("thead", null, tr));
        var tb = h("tbody");
        rows.forEach(function (r) {
          var row = h("tr");
          r.forEach(function (v, i) { row.appendChild(h("td", { class: i ? "num" : "", text: String(v) })); });
          if (withBar) row.appendChild(h("td", { style: "width:30%" }, h("div", { class: "bar", style: "width:" + Math.round(100 * r[r.length - 1] / max) + "%" })));
          tb.appendChild(row);
        });
        t.appendChild(tb);
        return h("div", { class: "table-wrap" }, t);
      }
      box.appendChild(h("h2", { text: "Per fastighet" }));
      box.appendChild(tbl(["Fastighet", "Akuta", "Ej klara", "Totalt"], s.perFastighet.map(function (p) { return [p.namn, p.akuta, p.oppna, p.antal]; }), true));
      box.appendChild(h("h2", { text: "Per månad" }));
      box.appendChild(tbl(["Månad", "Antal"], s.perManad.map(function (m) { return [fmtMonth(m.manad), m.antal]; }), true));
      box.appendChild(h("h2", { text: "Per kategori" }));
      box.appendChild(tbl(["Kategori", "Antal"], s.perKategori.map(function (k) { return [k.kategori, k.antal]; }), true));
    }).catch(function (e) { clear(box); box.appendChild(error(e.message)); });
  }

  // ---------- shell ----------
  var TABS = {
    hyresgast: [["Mina ärenden", function () { showMyTickets(); }], ["Felanmäl", showReport], ["Dokument", showDocs]],
    forvaltare: [["Ärenden", showManager], ["Dokument", showDocs], ["Statistik", showStats]],
    ekonomi: [["Statistik", showStats]]
  };

  function buildTabs() {
    clear(tabsEl);
    var tabs = TABS[me.roll] || [];
    tabs.forEach(function (t, i) {
      var b = h("button", { type: "button", role: "tab", "aria-selected": i === 0 ? "true" : "false", text: t[0] });
      b.addEventListener("click", function () {
        Array.prototype.forEach.call(tabsEl.children, function (x) { x.setAttribute("aria-selected", "false"); });
        b.setAttribute("aria-selected", "true"); t[1]();
      });
      tabsEl.appendChild(b);
    });
    if (tabs.length) tabs[0][1]();
  }

  api("/api/me").then(function (m) {
    me = m;
    document.getElementById("who").hidden = false;
    document.getElementById("who-name").textContent = m.namn + " (" + (ROLE[m.roll] || m.roll) + ")";
    if (m.roll === "hyresgast" && m.enhet) {
      var u = document.getElementById("who-unit");
      var prop = m.fastigheter && m.fastigheter[0];
      u.textContent = (prop && prop.namn ? prop.namn + ", " : "") + "enhet " + m.enhet;
      u.hidden = false;
    }
    if (m.demo) { document.getElementById("demo-bar").hidden = false; document.getElementById("logout").hidden = true; }
    buildTabs();
  }).catch(function (e) { clear(view); view.appendChild(error(e.message)); });
})();
