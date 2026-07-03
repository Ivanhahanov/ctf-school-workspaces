// Dedicated Firefox profile for the IDE window.
// - enable userChrome.css (hides Firefox's own tabs/address bar → app-like)
// - browser.tabs.inTitlebar=0 forces the XFCE window title bar (server-side),
//   so the window ALWAYS has clickable Minimize / Close buttons (no keyboard).
user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);
user_pref("browser.tabs.inTitlebar", 0);
user_pref("browser.aboutConfig.showWarning", false);
user_pref("browser.shell.checkDefaultBrowser", false);
