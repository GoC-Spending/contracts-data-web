// Helper JS functions for the contracting analysis site

// With thanks to,
// https://stackoverflow.com/a/13147238/756641
function externalLinks() {
for(var c = document.getElementsByTagName("a"), a = 0;a < c.length;a++) {
    var b = c[a];
    b.getAttribute("href") && b.hostname !== location.hostname && (b.target = "_blank")
}
}
;

(function () {
externalLinks();
})(); 
