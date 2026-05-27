document.head.insertAdjacentHTML("afterbegin", `
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>`);
const fontIsolation = (async () => {
  const PAGY_WAND_FONT_CACHE_KEY = "pagy-wand-processed-fonts";
  const cachedDataJson = sessionStorage.getItem(PAGY_WAND_FONT_CACHE_KEY);
  if (cachedDataJson) {
    try {
      const cachedData = JSON.parse(cachedDataJson);
      if (typeof cachedData.fontFaceRules === "string" && typeof cachedData.processedComponentCss === "string") {
        if (cachedData.fontFaceRules) {
          const styleEl = document.createElement("style");
          styleEl.id = "pagy-wand-font-css";
          styleEl.textContent = cachedData.fontFaceRules;
          if (document.head) {
            document.head.appendChild(styleEl);
          } else {
            document.addEventListener("DOMContentLoaded", () => document.head.appendChild(styleEl), { once: true });
          }
        }
        return { processedComponentCss: cachedData.processedComponentCss };
      } else {
        console.warn("Pagy Wand: Invalid cached font data structure found. Refetching.");
        sessionStorage.removeItem(PAGY_WAND_FONT_CACHE_KEY);
      }
    } catch (e) {
      console.error("Pagy Wand: Failed to parse cached font data. Refetching.", e);
      sessionStorage.removeItem(PAGY_WAND_FONT_CACHE_KEY);
    }
  }
  const icons = "check_circle,content_copy,error,help,tune,visibility,visibility_off";
  const fontDefinitions = [
    {
      url: "https://fonts.googleapis.com/css2?family=Nunito+Sans:ital,opsz,wght@0,6..12,200..1000;1,6..12,200..1000&family=Ubuntu+Sans+Mono:ital,wght@0,400..700;1,400..700&display=swap",
      fontMappings: [
        { original: "Nunito Sans", custom: "PagyWand-Sans" },
        { original: "Ubuntu Sans Mono", custom: "PagyWand-Mono" }
      ]
    },
    {
      url: "https://fonts.googleapis.com/css2?family=Pattaya&text=PagyWand&display=swap",
      fontMappings: [
        { original: "Pattaya", custom: "PagyWand-Logo" }
      ]
    },
    {
      url: `https://fonts.googleapis.com/css2?family=Material+Symbols+Rounded:opsz,wght,GRAD@20..48,300,-50..200&icon_names=${icons}&display=block`,
      fontMappings: [
        { original: "Material Symbols Rounded", custom: "PagyWand-Symbols" }
      ],
      classMappings: [
        { original: "material-symbols-rounded", custom: "pagy-wand-symbol" }
      ]
    }
  ];
  async function processGoogleFontCSS(fontCssUrl, fontMappings = [], classMappings = []) {
    const result = { fontFaceRules: "", componentCss: "" };
    try {
      const response = await fetch(fontCssUrl);
      if (!response.ok)
        throw new Error(`Font CSS fetch failed (${response.status})`);
      let cssText = await response.text();
      fontMappings.forEach((mapping) => {
        const regex = new RegExp(`(font-family:\\s*['"]?)${mapping.original}(['"]?;?)`, "g");
        cssText = cssText.replace(regex, `$1${mapping.custom}$2`);
      });
      classMappings.forEach((mapping) => {
        const regex = new RegExp(`\\.(${mapping.original})(?=[\\s\\.{,:])`, "g");
        cssText = cssText.replace(regex, `.${mapping.custom}`);
      });
      const fontFaceRegex = /(?:\/\*[\s\S]*?\*\/[\s\n]*)?@font-face\s*\{[^}]*}/g;
      const fontFaceMatches = cssText.match(fontFaceRegex);
      result.fontFaceRules = fontFaceMatches ? fontFaceMatches.join(`

`) : "";
      result.componentCss = cssText.replace(fontFaceRegex, "").trim();
    } catch (error) {
      console.error("Failed to process Google Font CSS:", fontCssUrl, error);
      throw error;
    }
    return result;
  }
  const processedResults = await Promise.all(fontDefinitions.map((def) => processGoogleFontCSS(def.url, def.fontMappings, def.classMappings)));
  const allFontFaceRules = processedResults.map((r) => r.fontFaceRules).join(`
`);
  const allComponentCss = processedResults.map((r) => r.componentCss).join(`
`);
  if (allFontFaceRules) {
    const styleEl = document.createElement("style");
    styleEl.id = "pagy-wand-font-css";
    styleEl.textContent = allFontFaceRules;
    if (document.head) {
      document.head.appendChild(styleEl);
    } else {
      document.addEventListener("DOMContentLoaded", () => document.head.appendChild(styleEl), { once: true });
    }
  }
  try {
    const dataToCache = {
      fontFaceRules: allFontFaceRules,
      processedComponentCss: allComponentCss
    };
    sessionStorage.setItem(PAGY_WAND_FONT_CACHE_KEY, JSON.stringify(dataToCache));
  } catch (e) {
    console.error("Pagy Wand: Failed to save font data to sessionStorage.", e);
  }
  return { processedComponentCss: allComponentCss };
})();
document.addEventListener("DOMContentLoaded", async () => {
  const PRESET = "pagy-wand-preset";
  const OVERRIDE = "pagy-wand-override";
  const POSITION = "pagy-wand-position";
  const CONTROLS_CHK = "pagy-wand-controls-chk";
  const HELP_CHK = "pagy-wand-help-chk";
  const LIVE_CHK = "pagy-wand-live-chk";
  const normalize = (str) => str.trim().replace(/\s+/g, " ");
  function getSessionItem(key) {
    return sessionStorage.getItem(key);
  }
  function setSessionItem(key, value) {
    if (typeof value === "string") {
      sessionStorage.setItem(key, value);
    } else {
      sessionStorage.setItem(key, JSON.stringify(value));
    }
  }
  function removeSessionItem(key) {
    sessionStorage.removeItem(key);
  }
  function getSessionBoolean(key, defaultValue) {
    const value = sessionStorage.getItem(key);
    return value !== null ? JSON.parse(value) : defaultValue;
  }
  function getSessionObject(key) {
    const value = sessionStorage.getItem(key);
    return value ? JSON.parse(value) : null;
  }
  function hslaToRgba(hsla) {
    const h = parseFloat(hsla.hue) / 360;
    const s = parseFloat(hsla.saturation) / 100;
    const l = parseFloat(hsla.lightness) / 100;
    const a = parseFloat(hsla.alpha);
    let r, g, b;
    if (s === 0) {
      r = g = b = l;
    } else {
      const hue2rgb = (p, q, t) => {
        if (t < 0)
          t += 1;
        if (t > 1)
          t -= 1;
        if (t < 1 / 6)
          return p + (q - p) * 6 * t;
        if (t < 1 / 2)
          return q;
        if (t < 2 / 3)
          return p + (q - p) * (2 / 3 - t) * 6;
        return p;
      };
      const q = l < 0.5 ? l * (1 + s) : l + s - l * s;
      const p = 2 * l - q;
      r = hue2rgb(p, q, h + 1 / 3);
      g = hue2rgb(p, q, h);
      b = hue2rgb(p, q, h - 1 / 3);
    }
    const toHex = (x) => Math.round(x * 255).toString(16).padStart(2, "0");
    return `#${toHex(r)}${toHex(g)}${toHex(b)}${toHex(a)}`;
  }
  function rgbaToHsla(rgba) {
    const r = parseInt(rgba.slice(1, 3), 16) / 255;
    const g = parseInt(rgba.slice(3, 5), 16) / 255;
    const b = parseInt(rgba.slice(5, 7), 16) / 255;
    const a = parseInt(rgba.slice(7, 9), 16) / 255;
    const max = Math.max(r, g, b), min = Math.min(r, g, b);
    let h = 0, s, l = (max + min) / 2;
    if (max === min) {
      h = s = 0;
    } else {
      const d = max - min;
      s = l > 0.5 ? d / (2 - max - min) : d / (max + min);
      switch (max) {
        case r:
          h = (g - b) / d + (g < b ? 6 : 0);
          break;
        case g:
          h = (b - r) / d + 2;
          break;
        case b:
          h = (r - g) / d + 4;
          break;
      }
      h /= 6;
    }
    return {
      hue: (h * 360).toFixed(2),
      saturation: (s * 100).toFixed(2),
      lightness: (l * 100).toFixed(2),
      alpha: a.toFixed(3)
    };
  }
  const host = document.createElement("div");
  host.id = "pagy-wand-host";
  document.body.appendChild(host);
  const s = parseFloat(document.getElementById("pagy-wand").getAttribute("data-scale"));
  const sliderHeight = s;
  const thumbDiameter = s * 1.2;
  const baseColor = "#484848";
  const lightGray = "rgba(220,220,220,.6)";
  const wandColor = "#81ffff";
  const wandTint = "rgba(190,220,220,.6)";
  const remSize = parseFloat(getComputedStyle(document.documentElement).fontSize);
  const style = document.getElementById("pagy-wand-default");
  document.head.appendChild(style);
  const shadow = host.attachShadow({ mode: "closed" });
  const { processedComponentCss } = await fontIsolation;
  shadow.innerHTML = `
    <!--suppress CssInvalidPropertyValue -->
    <style>
      ${processedComponentCss}
      #panel select, #panel select option, #panel input[type="range"] {
        font-family: 'PagyWand-Sans', sans-serif;
        cursor: pointer;
        font-weight: 600;
      }
      #panel select, textarea {
        font-size: ${s * 0.8}rem;
        border-radius: ${s}rem;
        padding-left: ${s * 0.25}rem !important;
        border: none;
        box-shadow: inset 0 0 ${s * 0.2}rem ${wandColor};
      }
      #panel {
        accent-color: ${baseColor};
        font-family: 'PagyWand-Sans', sans-serif;
        line-height: 1.2;
        border-radius: ${s * 1.25}rem;
        width: ${s * 22}rem;
        box-sizing: border-box;
        box-shadow: ${s * 0.75}rem
                    ${s * 0.75}rem
                    ${s * 1.5625}rem
                    ${s * 0.0625}rem
                    rgba(0,0,0,.4);
        position: fixed;
        z-index: 10000;
        overflow: hidden;
      }
      #panel.initial {
        top: 0;
        left: 0;
        transform: translate(-50%, 0) scale(0.1) rotate(0deg);
      }
      #panel.centered {
        transition: transform 2.5s ease-in-out;
        transform: translate(calc(50vw - 50%), calc(50vh - 50%)) scale(1) rotate(2160deg);
      }
      #panel pre, #panel code, #panel kbd, #panel samp {
        font-family: 'PagyWand-Mono', monospace;
      }
      #top-bar {
        background: linear-gradient(to bottom,
                                      #1a1a1a 0%,
                                      #2b2b2b 5%,
                                      #404040 10%,
                                      #525252 20%,
                                      #404040 40%,
                                      #2b2b2b 60%,
                                      #1a1a1a 80%,
                                      #0d0d0d 92%,
                                      #000000 100%
                                    );
        padding: ${s * 0.25}rem
                 ${s * 0.75}rem
                 ${s * 0.25}rem
                 ${s * 0.875}rem;
        cursor: move;
        user-select: none;
        color: white;
        display: flex;
        align-items: center;
        justify-content: space-between;
        box-shadow: inset 0 0 ${s * 0.2}rem ${wandColor};
      }
      #top-bar label {
        display: flex;
        align-items: center;
      }
      #top-bar label input[type="checkbox"] {
        display: none;
      }
      #title {
        color: ${wandColor};
        font-family: 'PagyWand-Logo', sans-serif;
        font-size: ${s * 1.4}rem;
        text-shadow: ${s * 0.0625}rem
                     ${s * 0.0625}rem
                     0 rgba(0,0,0,1);
        margin-right: ${s * 0.125}rem;
      }
      .switch-icon {
        font-size: ${s * 1.5}rem;
        font-weight: 300;
        cursor: pointer;
      }
      .selected-icon {
        color: ${wandColor};
      }
      .content{
        overflow-y: auto;
        font-size: ${s * 0.8}rem;
        color: black;
        backdrop-filter: blur(${s * 0.875}rem);
        padding: ${s * 0.8}rem 0;
        border-top: ${s * 0.15}rem solid ${wandColor};
        border-bottom: ${s * 0.15}rem solid ${wandColor};
        height: ${s * 33}rem;
        background: linear-gradient(to bottom,
                                      ${wandTint}  0%,
                                      ${lightGray} 5%,
                                      ${lightGray} 95%,
                                      ${wandTint}  100%
                                   );
      }
      .controls {
        border-top: ${s * 0.0625}rem solid #ccc;
        border-bottom: ${s * 0.0625}rem solid #aaa;
        display: grid;
        grid-template-columns: 1fr 3fr;
        grid-column-gap: ${s * 0.625}rem;
        padding: ${s * 0.25}rem ${s}rem;
      }
      .controls-brightness {
        padding-top: 0;
        border-top: none;
        grid-template-rows: ${s * 1.5}rem;
      }
      .controls-color {
        grid-template-rows: repeat(5, ${s * 1.3}rem);
      }
      .controls-layout {
        grid-template-rows: repeat(4, ${s * 1.3}rem);
      }
      .controls-typography {
        grid-template-rows: repeat(3, ${s * 1.3}rem);
      }
      .controls-override {
        grid-template-rows: ${s * 12.9}rem;
        margin-bottom: ${s * 0.125}rem;
        border-bottom: none;
      }
      .controls label {
        font-weight: 600;
        grid-column: 1;
        white-space: nowrap;
        justify-self: end;
        align-self: center;
        user-select: none;
        cursor: default;
      }
      .controls input {
        margin: 0;
        align-self: center;
      }
      #brightness {
        margin: 0 0 ${s * 0.2}rem 0;
        color: white;
        background-color: black;
        opacity: .6;
      }
      #hue, #saturation, #lightness, #alpha {
        -webkit-appearance: none;
        appearance: none;
        width: 1fr;
        border-radius: ${s * 0.5}rem;
        outline: none;
        height: ${sliderHeight}rem;
        box-shadow: inset 0 0 ${s * 0.1}rem rgba(0,0,0,0.5);
        box-sizing: border-box;
      }
      #hue::-webkit-slider-thumb,
      #saturation::-webkit-slider-thumb,
      #lightness::-webkit-slider-thumb,
      #alpha::-webkit-slider-thumb {
        -webkit-appearance: none;
        appearance: none;
        box-sizing: border-box;
        width: ${thumbDiameter}rem;
        height: ${thumbDiameter}rem;
        background: transparent;
        border: ${s * 0.15}rem solid ${baseColor};
        border-radius: 50%;
        cursor: pointer;
      }
      #hue::-moz-range-thumb,
      #saturation::-moz-range-thumb,
      #lightness::-moz-range-thumb,
      #alpha::-moz-range-thumb {
        box-sizing: border-box;
        width: ${thumbDiameter}rem;
        height: ${thumbDiameter}rem;
        background: transparent;
        border: ${s * 0.15}rem solid ${baseColor};
        border-radius: 50%;
        cursor: pointer;
      }
      #alpha {
        background-size: auto, ${s * 0.5}rem ${s * 0.5}rem; /* gradient, grid */
        background-repeat: no-repeat, repeat;         /* gradient, grid *//
      }
      #hex8-container {
        display: flex;
      }
      #hex8, #color-sample {
        border: none;
        border-radius: ${s * 0.5}rem;
        height: ${sliderHeight}rem;
      }
      #hex8 {
        box-sizing: border-box;
        width: ${s * 5}rem;
        text-align: center;
        font-family: "PagyWand-Mono", monospace;
        font-weight: 500;
        line-height: 1.1;
        color: white;
        background-color: black;
        border-top-right-radius: 0;
        border-bottom-right-radius: 0;
        opacity: .6;
      }
      #color-sample {
        width: 100%;
        border-top-left-radius: 0;
        border-bottom-left-radius: 0;
        align-self: center;
        box-shadow: inset 0 0 ${s * 0.1}rem rgba(0,0,0,0.5);
        background-size: auto, ${s * 0.5}rem ${s * 0.5}rem; /* gradient, grid */
        background-repeat: no-repeat, repeat;         /* gradient, grid *//
      }
      label[for="override"] {
        align-self: start !important;
        margin-top: ${s * 0.35}rem;
      }
      #override-container {
        display: inline;
        position: relative;
      }
      #override {
        white-space: pre-wrap; /* Preserve line breaks, wrap only when necessary */
        word-break: normal;    /* Prevent breaking words */
        overflow-wrap: normal; /* Standard line breaking */
        font-family: "PagyWand-Mono", monospace;
        padding: ${s * 0.2}rem !important;
        border-radius: ${s * 0.6}rem;
        line-height: 1.1;
        height: 100%;
        width: 100%;
        resize: none;
        font-weight: 500;
        box-sizing: border-box;
        position: relative;
        margin-top: ${s * 0.25}rem;
        color: white;
        background-color: black;
        opacity: .6;
      }
      #copy-icon {
        font-weight: 300;
        color: ${lightGray};
        position: absolute;
        top: ${s * 0.8}rem;
        right: ${s}rem;
        cursor: pointer;
      }
      .copy-feedback {
        position: absolute;
        top: ${s}rem;
        right: ${s * 2.7}rem;
        padding: ${s * 0.1}rem ${s * 0.3}rem;
        border-radius: ${s * 0.2}rem;
        font-weight: 700;
        white-space: nowrap;
        align-self: center;
        color: white;
        opacity: 0;
        visibility: hidden;
        transition: opacity 0.4s ease-in-out, visibility 0.2s ease-in-out;
        pointer-events: none; /* Prevent interfering with clicks */
      }
      .copy-feedback.visible {
        opacity: 1;
        visibility: visible;
      }
      .copy-feedback.success {
        background-color: limegreen;
      }
      .copy-feedback.failure {
        background-color: red;
      }
      #help {
        padding-left: ${s}rem;
        padding-right: ${s}rem;
      }
      .help-icon, .help-copy-icon {
        font-size: ${s}rem;
        vertical-align: -15.625%;
        border-radius: 15%;
        color: white;
        background-color: ${baseColor};
        margin-top: ${s * 0.2}rem;
        padding: ${s * 0.125}rem
                 ${s * 0.0625}rem
                 ${s * 0.0625}rem
                 ${s * 0.0625}rem;
        font-weight: 300;
      }
      .selected-help-icon {
        color: ${wandColor};
      }
       .help-copy-icon {
         color: ${baseColor};
         background-color: white;
       }
      .help-copy-icon.success {
        color: limegreen;
      }
      .help-copy-icon.failure {
        color: red;
      }
      #help {
        display: none;
        line-height: ${s}rem;
        scrollbar-width: none;
      }
      #help::-webkit-scrollbar {
        display: none;
      }
      #help > h4:first-child {
        margin-top: 0;
      }
      #help h4 {
        text-align: right;
        padding: ${s * 0.25}rem ${s * 0.625}rem;
        border-top-right-radius: ${s * 2.5}rem;
        border-bottom-right-radius: 2.5rem;
        color: white;
        background: linear-gradient(to right, rgba(0,0,0,0), rgba(0,0,0,.5));
        margin-top: ${s * 0.8}rem;
        margin-bottom: ${s * 0.4}rem;
      }
      #help p {
        margin-top: ${s * 0.4}rem;
        margin-bottom: ${s * 0.3}rem;
      }
      #help dl {
        margin: 0;
      }
      #help dt {
        font-weight: 700;
        margin: ${s * 0.4}rem 0 ${s * 0.1}rem 0;
      }
      #help dd {
        margin-bottom: ${s * 0.15}rem;
        margin-left: ${s}rem;
      }
      #help .button-desc {
        margin-left: ${s * 0.4}rem;
      }
      #help code {
        font-family: "PagyWand-Mono", monospace;
        font-weight: 400;
        display: inline-block;
        line-height: ${s * 0.8}rem;
        border-radius: ${s * 0.625}rem;
        background-color: white;
        padding: ${s * 0.0625}rem ${s * 0.3125}rem;
      }
    </style>
    <div id="panel">
      <div id="top-bar">
        <span id="title">PagyWand</span>
        <label for="preset-menu">
          <select id="preset-menu">
            <option value="" disabled>Presets...</option>
          </select>
        </label>
        <label for="controls-chk">
          <input id="controls-chk" type="checkbox">
          <span class="pagy-wand-symbol switch-icon" id="controls-icon">tune</span>
        </label>
        <label for="help-chk">
          <input id="help-chk" type="checkbox">
          <span class="pagy-wand-symbol switch-icon" id="help-icon">help</span>
        </label>
        <label for="live-chk">
          <input id="live-chk" type="checkbox" checked>
          <span class="pagy-wand-symbol switch-icon" id="live-icon">visibility</span>
        </label>
      </div>
      <div id="content">
        <div id="controls" class="content">
          <div class="controls controls-brightness light-bknd">
            <label for="brightness">Brightness</label>
            <select id="brightness">
              <option value="1">Light</option>
              <option value="-1">Dark</option>
            </select>
          </div>
          <div class="controls controls-color dark-bknd">
            <label for="hue">Hue</label>
            <input type="range" id="hue" min="0" max="360" step="0.01">
            <label for="saturation">Saturation</label>
            <input type="range" id="saturation" min="0" max="100" step="0.01">
            <label for="lightness">Lightness</label>
            <input type="range" id="lightness" min="0" max="100" step="0.01">
            <label for="alpha">Alpha</label>
            <input type="range" id="alpha" min="0" max="1" step="0.001">
            <label for="hex8">Hex8</label>
            <div id="hex8-container">
              <input type="text" id="hex8" spellcheck="false">
              <span id="color-sample"></span>
            </div>
          </div>
          <div class="controls controls-layout light-bknd">
            <label for="spacing">Spacing</label>
            <input type="range" id="spacing" min="0" max="1.5" step="0.0625">
            <label for="padding">Padding</label>
            <input type="range" id="padding" min="0" max="1.5" step="0.0625">
            <label for="rounding">Rounding</label>
            <input type="range" id="rounding" min="0" max="3" step="0.0625">
            <label for="borderWidth">Borders</label>
            <input type="range" id="borderWidth" min="0" max="0.25" step="0.03125">
          </div>
          <div class="controls controls-typography dark-bknd">
            <label for="fontSize">Font Size</label>
            <input type="range" id="fontSize" min="0.75" max="2" step="0.0625">
            <label for="fontWeight">Font Weight</label>
            <input type="range" id="fontWeight" min="100" max="1000" step="50">
            <label for="lineHeight">Line Height</label>
            <input type="range" id="lineHeight" min="1.25" max="2.5" step="0.0625">
          </div>
          <div class="controls controls-override light-bknd">
            <label for="override">CSS Override</label>
            <div id="override-container">
              <textarea id="override" readonly></textarea>
              <span id="copy-feedback" class="copy-feedback"></span>
              <span id="copy-icon" class="pagy-wand-symbol">content_copy</span>
            </div>
          </div>
        </div>
        <div id="help" class="content">
          <h4>Install</h4>
            <dl>
              <dt>Add this line in your HTML head</dt>
              <dd>
                <p><code><%== Pagy.dev_tools %></code></p>
                <p>You can pass the optional <code>wand_scale</code> argument to change the size of the Wand.
                  <br>Default: <code>wand_scale: 1</code></p>
              </dd>
            </dl>
          <h4>Wand</h4>
          <dl>
            <dt>Top Bar</dt>
              <dd>Drag the Wand.</dd>
            <dt>Top Bar Indicator Buttons</dt>
              <dd>
                <ul style="list-style-type: none; padding-left: 0; margin: 0;">
                  <li><span class="pagy-wand-symbol help-icon">tune</span> <span class="pagy-wand-symbol help-icon selected-help-icon">tune</span><span class="button-desc">Toggle the Controls Section</span></li>
                  <li><span class="pagy-wand-symbol help-icon">help</span> <span class="pagy-wand-symbol help-icon selected-help-icon">help</span><span class="button-desc">Toggle the Help Section</span></li>
                  <li><span class="pagy-wand-symbol help-icon">visibility_off</span> <span class="pagy-wand-symbol help-icon selected-help-icon">visibility</span><span class="button-desc">Toggle the Live Preview</span></li>
                </ul>
              </dd>
            <dt>Presets</dt>
              <dd>Pick a starting point to try and further customize.</dd>
            <dt>Close Icon</dt>
              <dd>There is no dynamic close button by design, so you won't forget to remove it in production.</dd>
          </dl>
          <h4>Controls</h4>
          <dl>
            <dt>Brightness</dt>
              <dd>Toggle between Light and Dark theming calculation. Adjust the lightness after toggling.</dd>
            <dt>Hue, Saturation, Lightness, Alpha</dt>
              <dd>Generate any color. Notice that the automatic calculations work better within certain ranges/combinations.</dd>
            <dt>Hex8</dt>
              <dd>8-digit hex-color code: useful to quickly copy/paste and match a color from your app.</dd>
            <dt>Spacing, Padding, Rounding, Borders</dt>
              <dd>Control the layout and overall look.</dd>
            <dt>Font Size, Font Weight, Line Height</dt>
              <dd>Control the typography of the page links. Notice that the <code>font-family</code> is inherited from your app.</dd>
            <dt>Interactions</dt>
              <dd>The combination of Padding, Font Size, Line Height, controls the internal proportions of the page links.</dd>
            <dt>CSS Override</dt>
              <dd>
                The current set of <code>.pagy</code> rules.
                <ul style="list-style-type: none; padding-left: 0; margin: 0;">
                  <li><span class="pagy-wand-symbol help-copy-icon">content_copy</span> <span class="button-desc">Copy the CSS Override</span></li>
                  <li><span class="pagy-wand-symbol help-copy-icon success">check_circle</span> <span class="button-desc">Copied! Feedback</li>
                  <li><span class="pagy-wand-symbol help-copy-icon failure">error</span> <span class="button-desc">Failed! Feedback</li>
                </ul>
              </dd>
          </dl>
          <h4>Customizing</h4>
          <p>• You can change Pagy's styling quite radically, by just setting a few CSS Custom Properties:
            the <code><i>pagy.css</i></code> or <code><i>pagy-tailwind.css</i></code> calculates all the other metrics.</p>
          <p>• Pick a Presets as a starting point, customize it with the controls,
            and copy/paste the CSS Override in your Stylesheet.</p>
          <p>• Add further customization to the <code>.pagy</code> CSS Override, or override the calculated properties
            for full control over the final style.</p>
          <p><b>Important</b>: Do not link the Pagy CSS file. Copy its customized content in your CSS,
            to avoid unwanted cosmetic changes that could happen on update.</p>
        </div>
      </div>
    </div>
  `;
  const styleTagOverride = document.createElement("style");
  styleTagOverride.id = "pagy-wand-override";
  document.head.appendChild(styleTagOverride);
  const panel = shadow.getElementById("panel");
  const topBar = shadow.getElementById("top-bar");
  const presetMenu = shadow.getElementById("preset-menu");
  const controlsChk = shadow.getElementById("controls-chk");
  controlsChk.checked = getSessionBoolean(CONTROLS_CHK, false);
  const controlsIcon = shadow.getElementById("controls-icon");
  const controlsDiv = shadow.getElementById("controls");
  const helpChk = shadow.getElementById("help-chk");
  helpChk.checked = getSessionBoolean(HELP_CHK, false);
  const helpIcon = shadow.getElementById("help-icon");
  const helpDiv = shadow.getElementById("help");
  const liveChk = shadow.getElementById("live-chk");
  liveChk.checked = getSessionBoolean(LIVE_CHK, true);
  const liveIcon = shadow.getElementById("live-icon");
  const liveStyle = document.getElementById("pagy-wand-default");
  const copyIcon = shadow.getElementById("copy-icon");
  const overrideArea = shadow.getElementById("override");
  let controls = {
    brightness: { name: "--B", unit: "" },
    hue: { name: "--H", unit: "" },
    saturation: { name: "--S", unit: "" },
    lightness: { name: "--L", unit: "" },
    alpha: { name: "--A", unit: "" },
    hex8: { name: "", unit: "" },
    spacing: { name: "--spacing", unit: "rem" },
    padding: { name: "--padding", unit: "rem" },
    rounding: { name: "--rounding", unit: "rem" },
    borderWidth: { name: "--border-width", unit: "rem" },
    fontSize: { name: "--font-size", unit: "rem" },
    fontWeight: { name: "--font-weight", unit: "" },
    lineHeight: { name: "--line-height", unit: "" }
  };
  function updateColorRamps() {
    const b = controls.brightness.input.value;
    let darker, lighter;
    if (b === "-1") {
      darker = "black";
      lighter = "%23404040";
    } else {
      darker = "%23B0B0B0";
      lighter = "white";
    }
    const gridUrl = `url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='10' height='10'%3E%3Crect width='5' height='5' fill='${darker}'/%3E%3Crect x='5' width='5' height='5' fill='${lighter}'/%3E%3Crect y='5' width='5' height='5' fill='${lighter}'/%3E%3Crect x='5' y='5' width='5' height='5' fill='${darker}'/%3E%3C/svg%3E")`;
    const h = controls.hue.input.value;
    const s = controls.saturation.input.value;
    const l = controls.lightness.input.value;
    const a = controls.alpha.input.value;
    const sliderWidth = controls.alpha.input.getBoundingClientRect().width;
    const thumbRadius = remSize * thumbDiameter / 2;
    const startSlider = thumbRadius + "px";
    const endSlider = sliderWidth - thumbRadius + "px";
    controls.hue.input.style.background = `linear-gradient(to right, hsl(0 100 50) ${startSlider}, hsl(60 100 50), hsl(120 100 50), hsl(180 100 50), hsl(240 100 50), hsl(300 100 50), hsl(360 100 50) ${endSlider})`;
    controls.saturation.input.style.background = `linear-gradient(to right, hsl(${h} 0 ${l}) ${startSlider}, hsl(${h} 100 ${l}) ${endSlider})`;
    controls.lightness.input.style.background = `linear-gradient(to right, hsl(${h} ${s} 0) ${startSlider}, hsl(${h} ${s} 50), hsl(${h} ${s} 100) ${endSlider})`;
    controls.alpha.input.style.backgroundImage = `linear-gradient(to right, hsla(${h} ${s} ${l} / 0) ${startSlider}, hsla(${h} ${s} ${l} / 1) ${endSlider}), ${gridUrl}`;
    controls.hex8.input.value = hslaToRgba({ hue: h, saturation: s, lightness: l, alpha: a });
    const sample = shadow.getElementById("color-sample");
    sample.style.backgroundImage = `linear-gradient(to right, hsla(${h} ${s} ${l} / ${a}), hsla(${h} ${s} ${l} / ${a})), ${gridUrl}`;
  }
  const finalize = () => {
    updateOverride();
    presetMenu.value = "";
  };
  for (const [id, c] of Object.entries(controls)) {
    c.input = shadow.getElementById(id);
    if (id === "hex8") {
      c.input.addEventListener("change", () => {
        const hsla = rgbaToHsla(controls.hex8.input.value);
        controls.hue.input.value = hsla.hue;
        controls.saturation.input.value = hsla.saturation;
        controls.lightness.input.value = hsla.lightness;
        controls.alpha.input.value = hsla.alpha;
        finalize();
      });
    } else {
      c.input.addEventListener("input", () => {
        finalize();
      });
    }
  }
  const presets = {
    Default: `
      .pagy {
        --B: 1;
        --H: 0;
        --S: 0;
        --L: 50;
        --A: 1;
        --spacing: 0.125rem;
        --padding: 0.75rem;
        --rounding: 1.75rem;
        --border-width: 0rem;
        --font-size: 0.875rem;
        --font-weight: 600;
        --line-height: 1.75;
      }
    `,
    Dark: `
      .pagy {
        --B: -1;
        --H: 0;
        --S: 0;
        --L: 60;
        --A: 1;
        --spacing: 0.125rem;
        --padding: 0.75rem;
        --rounding: 1.75rem;
        --border-width: 0rem;
        --font-size: 0.875rem;
        --font-weight: 600;
        --line-height: 1.75;
      }
    `,
    MidnighExpress: `
      .pagy {
        --B: -1;
        --H: 231;
        --S: 28;
        --L: 60;
        --A: 1;
        --spacing: 0.1875rem;
        --padding: 1rem;
        --rounding: 0.375rem;
        --border-width: 0rem;
        --font-size: 1rem;
        --font-weight: 450;
        --line-height: 1.25;
      }
    `,
    Pilloween: `
      .pagy {
        --B: -1;
        --H: 20;
        --S: 80;
        --L: 50;
        --A: 1;
        --spacing: 0.375rem;
        --padding: 0.75rem;
        --rounding: 1.125rem;
        --border-width: 0.0625rem;
        --font-size: 0.875rem;
        --font-weight: 600;
        --line-height: 1.5;
      }
    `,
    Peppermint: `
      .pagy {
        --B: 1;
        --H: 78;
        --S: 70;
        --L: 38;
        --A: 1;
        --spacing: 0.1875rem;
        --padding: 0.625rem;
        --rounding: 0.75rem;
        --border-width: 0rem;
        --font-size: 0.875rem;
        --font-weight: 550;
        --line-height: 1.75;
      }
    `,
    CocoaBeans: `
      .pagy {
        --B: 1;
        --H: 27;
        --S: 63;
        --L: 17;
        --A: 1;
        --spacing: 0.0625rem;
        --padding: 0.5rem;
        --rounding: 1.125rem;
        --border-width: 0rem;
        --font-size: 0.875rem;
        --font-weight: 600;
        --line-height: 2.5;
      }
    `,
    PurpleStripe: `
      .pagy {
        --B: 1;
        --H: 255;
        --S: 63;
        --L: 43;
        --A: 1;
        --spacing: 0rem;
        --padding: 0.875rem;
        --rounding: 0rem;
        --border-width: 0rem;
        --font-size: 0.875rem;
        --font-weight: 300;
        --line-height: 1.5;
      }
    `,
    GhostInThought: `
      .pagy {
        --B: 1;
        --H: 174;
        --S: 40;
        --L: 70;
        --A: 1;
        --spacing: 0.125rem;
        --padding: 0.75rem;
        --rounding: 1.125rem;
        --border-width: 0rem;
        --font-size: 0.875rem;
        --font-weight: 450;
        --line-height: 1.75;
      }
    `,
    VintageScent: `
      .pagy {
        --B: 1;
        --H: 51;
        --S: 27;
        --L: 64;
        --A: 1;
        --spacing: 0.1875rem;
        --padding: 0.75rem;
        --rounding: 0.75rem;
        --border-width: 0.0625rem;
        --font-size: 0.875rem;
        --font-weight: 300;
        --line-height: 1.75;
      }
    `
  };
  for (const presetName in presets) {
    const option = document.createElement("option");
    option.value = presetName;
    option.textContent = presetName;
    presetMenu.appendChild(option);
  }
  presetMenu.value = "";
  presetMenu.addEventListener("change", (e) => {
    const name = e.target.value;
    setSessionItem(PRESET, name);
    applyCSS(presets[name]);
  });
  function applyCSS(css) {
    css.match(/--[^:]+:\s*[^;]+/g)?.forEach((match) => {
      let [cssVarName, value] = match.split(":");
      cssVarName = cssVarName.trim();
      value = value.trim().replace(/[a-zA-Z%]+$/, "");
      for (const c of Object.values(controls)) {
        if (c.name === cssVarName) {
          c.input.value = value;
          break;
        }
      }
    });
    updateOverride();
  }
  const initialOverride = getSessionItem(OVERRIDE);
  const presetName = getSessionItem(PRESET) ?? "Default";
  const presetCSS = normalize(presets[presetName]);
  if (initialOverride && initialOverride !== presetCSS) {
    applyCSS(initialOverride);
  } else {
    presetMenu.value = presetName;
    applyCSS(presetCSS);
  }
  function updateOverride() {
    let override = `.pagy {
`;
    Object.values(controls).forEach((c) => {
      if (c.name !== "") {
        override += `  ${c.name}: ${c.input.value}${c.unit};
`;
      }
    });
    override += "}";
    overrideArea.value = override;
    styleTagOverride.textContent = liveChk.checked ? override : "";
    setSessionItem(OVERRIDE, normalize(override));
    updateColorRamps();
  }
  function getSessionPosition() {
    return getSessionObject(POSITION);
  }
  function setSessionPosition(left, top) {
    setSessionItem(POSITION, { left: parseFloat(String(left)), top: parseFloat(String(top)) });
  }
  function keepTopBarInView() {
    const width = window.visualViewport ? window.visualViewport.width : document.documentElement.clientWidth;
    const height = window.visualViewport ? window.visualViewport.height : document.documentElement.clientHeight;
    const rect = topBar.getBoundingClientRect();
    let newLeft = panel.offsetLeft;
    let newTop = panel.offsetTop;
    if (rect.left < 0) {
      newLeft = panel.offsetLeft - rect.left;
    } else if (rect.right > width) {
      newLeft = panel.offsetLeft - (rect.right - width);
    }
    if (rect.top < 0) {
      newTop = panel.offsetTop - rect.top;
    } else if (rect.bottom > height) {
      newTop = panel.offsetTop - (rect.bottom - height);
    }
    panel.style.left = `${newLeft}px`;
    panel.style.top = `${newTop}px`;
    setSessionPosition(newLeft, newTop);
  }
  let resizeTimeout;
  window.addEventListener("resize", () => {
    if (resizeTimeout)
      clearTimeout(resizeTimeout);
    resizeTimeout = window.setTimeout(keepTopBarInView, 250);
  });
  const position = getSessionPosition();
  const wandPositioned = new CustomEvent("wand-positioned");
  if (position && !isNaN(position.left) && !isNaN(position.top)) {
    panel.style.left = `${position.left}px`;
    panel.style.top = `${position.top}px`;
    document.dispatchEvent(wandPositioned);
  } else {
    panel.classList.add("initial");
    requestAnimationFrame(() => {
      panel.classList.add("centered");
    });
    panel.addEventListener("transitionend", (e) => {
      if (e.propertyName === "transform") {
        panel.style.transition = "none";
        const rect = panel.getBoundingClientRect();
        panel.style.top = rect.top + "px";
        panel.style.left = rect.left + "px";
        setSessionPosition(rect.left, rect.top);
        panel.classList.remove("initial");
        panel.classList.remove("centered");
        document.dispatchEvent(wandPositioned);
      }
    }, { once: true });
  }
  let offsetX = 0;
  let offsetY = 0;
  let dragging = false;
  topBar.addEventListener("mousedown", (e) => {
    if (e.target.closest("#preset-menu, label"))
      return;
    dragging = true;
    offsetX = e.clientX - panel.offsetLeft;
    offsetY = e.clientY - panel.offsetTop;
    topBar.style.cursor = "grab";
  });
  document.addEventListener("mousemove", (e) => {
    if (!dragging)
      return;
    e.preventDefault();
    const newLeft = e.clientX - offsetX;
    const newTop = e.clientY - offsetY;
    panel.style.left = `${newLeft}px`;
    panel.style.top = `${newTop}px`;
  });
  document.addEventListener("mouseup", (e) => {
    if (!dragging)
      return;
    dragging = false;
    topBar.style.cursor = "move";
    const finalLeft = e.clientX - offsetX;
    const finalTop = e.clientY - offsetY;
    setSessionPosition(finalLeft, finalTop);
  });
  function controlsSwitcher() {
    if (controlsChk.checked) {
      controlsIcon.classList.add("selected-icon");
      controlsDiv.style.display = "grid";
      helpChk.checked = false;
      helpSwitcher();
      updateColorRamps();
    } else {
      controlsIcon.classList.remove("selected-icon");
      controlsDiv.style.display = "none";
    }
    setSessionItem(CONTROLS_CHK, controlsChk.checked);
  }
  controlsSwitcher();
  controlsChk.addEventListener("change", controlsSwitcher);
  function helpSwitcher() {
    if (helpChk.checked) {
      helpIcon.classList.add("selected-icon");
      helpDiv.style.display = "block";
      controlsChk.checked = false;
      controlsSwitcher();
    } else {
      helpIcon.classList.remove("selected-icon");
      helpDiv.style.display = "none";
    }
    setSessionItem(HELP_CHK, helpChk.checked);
  }
  helpSwitcher();
  helpChk.addEventListener("change", helpSwitcher);
  function liveSwitcher() {
    if (liveChk.checked) {
      liveIcon.classList.add("selected-icon");
      liveIcon.textContent = "visibility";
      liveStyle.disabled = false;
    } else {
      liveIcon.classList.remove("selected-icon");
      liveIcon.textContent = "visibility_off";
      liveStyle.disabled = true;
    }
    updateOverride();
    setSessionItem(LIVE_CHK, liveChk.checked);
  }
  liveSwitcher();
  liveChk.addEventListener("change", liveSwitcher);
  async function copyToClipboard() {
    const feedback = shadow.getElementById("copy-feedback");
    const originalIcon = "content_copy";
    feedback.classList.remove("visible");
    try {
      await navigator.clipboard.writeText(overrideArea.value);
      copyIcon.textContent = "check_circle";
      copyIcon.style.color = "limegreen";
      feedback.textContent = "Copied!";
      feedback.classList.add("visible", "success");
      setTimeout(() => {
        copyIcon.textContent = originalIcon;
        copyIcon.style.color = lightGray;
        feedback.classList.remove("visible", "success");
      }, 3000);
    } catch (err) {
      console.error('Failed to copy! (navigator.clipboard requires "localhost" or HTTPS) - ', err);
      copyIcon.textContent = "error";
      copyIcon.style.color = "red";
      feedback.textContent = "Failed!";
      feedback.classList.add("visible", "failure");
      setTimeout(() => {
        copyIcon.textContent = originalIcon;
        copyIcon.style.color = lightGray;
        feedback.classList.remove("visible", "failure");
      }, 5000);
    }
  }
  copyIcon.addEventListener("click", copyToClipboard);
  const transitionStyleTag = document.createElement("style");
  transitionStyleTag.id = "pagy-wand-transition";
  transitionStyleTag.textContent = `
    .pagy {
      transition: background-color 0.3s ease
    }
    .pagy a, .pagy label {
      transition: background-color 0.3s ease,
                  color 0.3s ease,
                  border-color 0.3s ease,
                  padding 0.3s ease,
                  margin-left 0.3s ease,
                  margin-right 0.3s ease,
                  font-size 0.3s ease,
                  font-weight 0.3s ease,
                  line-height 0.3s ease,
                  border-radius 0.3s ease
    }
    `;
  document.head.appendChild(transitionStyleTag);
});
