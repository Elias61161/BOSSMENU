// API helper - minimal version
(function() {
    'use strict';
    
    var resourceName = 'jobpanel';
    try {
        if (typeof GetParentResourceName !== 'undefined') {
            resourceName = GetParentResourceName();
        }
    } catch (e) {}
    
    window.API = {
        post: function(endpoint, data) {
            return fetch('https://' + resourceName + '/' + endpoint, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(data || {})
            }).catch(function() { return { ok: false }; });
        }
    };
})();