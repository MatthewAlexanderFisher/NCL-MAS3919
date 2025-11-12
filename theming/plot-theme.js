// plot-theme.js
import * as Plot from "@observablehq/plot";
import * as d3 from "d3";

const brand = {
  light: {
    // categorical colourway (matches your notes)
    range: ["#55C3CB", "#F39C65", "#A180DA", "#6CCFA7", "#E86D5A"],
    fg:    "#333333",
    bg:    "#FFFFFF",
    panel: "#F7F9FB",
    // continuous palette (teal → purple with a soft mint low end)
    interpolate: d3.interpolateRgbBasis(["#DDFFEB", "#55C3CB", "#A180DA"])
  },
  dark: {
    // slightly lighter hues for contrast on dark
    range: ["#5DDCE4", "#F7B77F", "#B59AF0", "#7FE3B5", "#F48A75"],
    fg:    "#EAEAEA",
    bg:    "#1E1E1E",
    panel: "#2A2D2E",
    interpolate: d3.interpolateRgbBasis(["#2A2D2E", "#5DDCE4", "#B59AF0"])
  }
};

function currentMode(mode = "auto") {
  if (mode !== "auto") return mode;
  const attr = document.documentElement?.dataset?.theme;
  if (attr === "dark") return "dark";
  if (attr === "light") return "light";
  return window.matchMedia?.("(prefers-color-scheme: dark)")?.matches ? "dark" : "light";
}

/** Apply Observable Plot defaults for light/dark. Call once on load. */
export function applyPlotTheme(mode = "auto") {
  const m = currentMode(mode);
  const t = brand[m];

  Plot.defaults({
    color: { range: t.range },          // categorical default
    grid: true,
    style: {
      // These affect the <figure> that Plot renders
      background: t.panel,              // plot panel background
      color: t.fg,                      // axis/legend text colour
      fontFamily: "system-ui, sans-serif"
    }
  });

  // expose a helper for continuous scales if you want a brand gradient:
  Plot.brandInterpolate = t.interpolate;
  Plot.brandMode = m;
}

/** Re-apply defaults automatically if OS or site theme toggles. */
export function watchPlotTheme() {
  const mm = window.matchMedia?.("(prefers-color-scheme: dark)");
  if (mm?.addEventListener) mm.addEventListener("change", () => applyPlotTheme("auto"));
  // If you toggle data-theme on <html>, re-apply after changes:
  const obs = new MutationObserver(() => applyPlotTheme("auto"));
  obs.observe(document.documentElement, { attributes: true, attributeFilter: ["data-theme"] });
}

export { brand };