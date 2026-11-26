// Firefox profile used only for the time log window (rl-open copies this in).
// Home is the time log; sound may play without a click (the break alarm);
// no first-run pages, update nags or "restore session?" after a power cut.
user_pref("browser.startup.homepage", "http://localhost:8765");
user_pref("browser.startup.page", 1);
user_pref("browser.sessionstore.resume_from_crash", false);
user_pref("browser.sessionstore.max_resumed_crashes", 0);
user_pref("browser.shell.checkDefaultBrowser", false);
user_pref("browser.aboutwelcome.enabled", false);
user_pref("browser.startup.homepage_override.mstone", "ignore");
user_pref("startup.homepage_welcome_url", "");
user_pref("startup.homepage_welcome_url.additional", "");
user_pref("datareporting.policy.dataSubmissionEnabled", false);
user_pref("datareporting.healthreport.uploadEnabled", false);
user_pref("toolkit.telemetry.reportingpolicy.firstRun", false);
user_pref("browser.tabs.warnOnClose", false);
user_pref("browser.warnOnQuit", false);
user_pref("media.autoplay.default", 0);
user_pref("media.autoplay.blocking_policy", 0);
user_pref("media.autoplay.block-webaudio", false);
user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);
