// ==UserScript==
// @name         New Userscript
// @namespace    http://tampermonkey.net/
// @version      0.1
// @description  try to take over the world!
// @author       You
// @match        https://addons.mozilla.org/en-US/firefox/addon/tampermonkey/
// @icon         https://www.google.com/s2/favicons?sz=64&domain=mozilla.org
// @grant        none
// ==/UserScript==

(function() {
    'use strict';
    let elements = document.querySelectorAll('[data-testid=awsc-nav-account-menu-button]');

    for (let element of elements) {
        element.style.font_size = "0px !important";
    }
    // Your code here...
})();