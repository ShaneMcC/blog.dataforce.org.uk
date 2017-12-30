/** Google Analytics. */
window.dataLayer = window.dataLayer || [];
function gtag(){dataLayer.push(arguments);}
gtag('js', new Date());
gtag('config', 'UA-2963238-1');

(function () {
	var s = document.createElement('script');
	s.type = 'text/javascript';
	s.async = true;
	s.src = 'https://www.googletagmanager.com/gtag/js?id=UA-2963238-1';
	var x = document.getElementsByTagName('script')[0];
	x.parentNode.insertBefore(s, x);
})();

/** A.DF.VG */
var _paq = _paq || [];
/* tracker methods like "setCustomDimension" should be called before "trackPageView" */
_paq.push(['trackPageView']);
_paq.push(['enableLinkTracking']);
(function() {
	var u="//a.df.vg/";
	_paq.push(['setTrackerUrl', u+'piwik.php']);
	_paq.push(['setSiteId', '1']);
	var d=document, g=d.createElement('script'), s=d.getElementsByTagName('script')[0];
	g.type='text/javascript'; g.async=true; g.defer=true; g.src=u+'piwik.js'; s.parentNode.insertBefore(g,s);
})();
