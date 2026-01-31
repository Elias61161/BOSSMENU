// ===== CORE FIVE Scripts - Job Panel =====
// ===== Version 4.0 - Custom Modals, Locales, Logo =====

(function() {
    'use strict';
    
    // ===== State =====
    var state = {
        job: '',
        grade: 0,
        permissions: {},
        employees: [],
        ranks: [],
        finances: { balance: 0, transactions: [] },
        vehicles: [],
        items: [],
        logs: [],
        branding: { 
            title: 'CORE FIVE Scripts', 
            subtitle: 'Job Management',
            logo: '',
            logoDark: '',
            logoLight: ''
        },
        locale: {},
        cart: [],
        selectedPlayer: null,
        currentMoneyAction: null,
        pendingConfirm: null,
        theme: 'dark'
    };
    
    // ===== Resource Name =====
    var resourceName = 'jobpanel';
    try {
        if (typeof GetParentResourceName !== 'undefined') {
            resourceName = GetParentResourceName();
        }
    } catch (e) {}
    
    // ===== DOM Ready =====
    document.addEventListener('DOMContentLoaded', function() {
        console.log('[JobPanel] Initializing...');
        
        // Load theme
        try {
            var saved = localStorage.getItem('jobpanel-theme');
            if (saved) state.theme = saved;
        } catch (e) {}
        
        applyTheme(state.theme);
        
        // Hide loading and app at start
        var loading = document.getElementById('loadingScreen');
        var app = document.getElementById('app');
        
        if (loading) loading.classList.add('hidden');
        if (app) app.classList.add('hidden');
        
        // Listen for NUI
        window.addEventListener('message', onMessage);
        
        // Escape to close
        document.addEventListener('keydown', function(e) {
            if (e.key === 'Escape') {
                closeAllModals();
                closePanel();
            }
        });
        
        console.log('[JobPanel] Ready');
    });
    
    // ===== Locale Function =====
    function L(key) {
        return state.locale[key] || key;
    }
    
    // ===== NUI Message Handler =====
    function onMessage(event) {
        var data = event.data;
        if (!data) return;
        
        console.log('[JobPanel] Message:', data.action);
        
        try {
            switch (data.action) {
                case 'openPanel':
                    handleOpenPanel(data);
                    break;
                case 'updateEmployees':
                    state.employees = data.employees || [];
                    renderEmployees();
                    renderDashboard();
                    break;
                case 'updateFinances':
                    state.finances = data.finances || { balance: 0, transactions: [] };
                    renderFinances();
                    break;
                case 'updateNearbyPlayers':
                    renderNearbyPlayers(data.players || []);
                    break;
                case 'notification':
                    showToast(data.type, data.message);
                    break;
                case 'close':
                    hideApp();
                    break;
            }
        } catch (err) {
            console.log('[JobPanel] Error:', err);
        }
    }
    
    // ===== Open Panel =====
    function handleOpenPanel(data) {
        console.log('[JobPanel] Opening panel...');
        
        // Show loading
        var loading = document.getElementById('loadingScreen');
        var app = document.getElementById('app');
        
        if (loading) loading.classList.remove('hidden');
        if (app) app.classList.add('hidden');
        
        // Store data
        state.job = data.job || '';
        state.grade = data.grade || 0;
        state.permissions = data.permissions || {};
        state.employees = data.employees || [];
        state.ranks = data.ranks || [];
        state.finances = data.finances || { balance: 0, transactions: [] };
        state.vehicles = data.vehicles || [];
        state.items = data.items || [];
        state.logs = data.logs || [];
        state.branding = data.branding || state.branding;
        state.locale = data.locale || {};
        state.cart = [];
        
        // Wait for loading animation
        setTimeout(function() {
            // Update UI
            updateHeader(data);
            updateLogos();
            applyPermissions();
            
            // Render all sections
            renderDashboard();
            renderEmployees();
            renderSalaries();
            renderRanks();
            renderFinances();
            renderVehicles();
            renderItems();
            renderLogs();
            renderCart();
            
            // Hide loading, show app
            if (loading) loading.classList.add('hidden');
            if (app) app.classList.remove('hidden');
            
            // Switch to dashboard
            switchTab('dashboard');
            
            console.log('[JobPanel] Panel opened');
        }, 1200);
    }
    
    // ===== Update Logos =====
    function updateLogos() {
        var logoDark = document.getElementById('logoDark');
        var logoLight = document.getElementById('logoLight');
        var loaderImg = document.querySelector('.loader-img');
        
        var darkUrl = state.branding.logoDark || state.branding.logo;
        var lightUrl = state.branding.logoLight || state.branding.logo;
        
        if (logoDark && darkUrl) {
            logoDark.src = darkUrl;
            logoDark.style.display = '';
        }
        
        if (logoLight && lightUrl) {
            logoLight.src = lightUrl;
        }
        
        if (loaderImg && darkUrl) {
            loaderImg.src = darkUrl;
        }
        
        // Update loading screen logo
        var loadingLogo = document.querySelector('.loader-img');
        if (loadingLogo && state.branding.logo) {
            loadingLogo.src = state.branding.logo;
        }
    }
    
    // ===== Hide App =====
    function hideApp() {
        var app = document.getElementById('app');
        var loading = document.getElementById('loadingScreen');
        
        if (app) app.classList.add('hidden');
        if (loading) loading.classList.add('hidden');
    }
    
    // ===== Close Panel =====
    function closePanel() {
        hideApp();
        postNUI('closePanel', {});
    }
    window.closePanel = closePanel;
    
    // ===== Post to NUI =====
    function postNUI(endpoint, data) {
        try {
            fetch('https://' + resourceName + '/' + endpoint, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(data || {})
            }).catch(function() {});
        } catch (e) {}
    }
    
    // ===== Theme =====
    function applyTheme(theme) {
        state.theme = theme;
        document.documentElement.setAttribute('data-theme', theme);
        
        var label = document.getElementById('themeLabel');
        if (label) {
            label.textContent = theme === 'dark' ? L('dark_mode') : L('light_mode');
        }
        
        try {
            localStorage.setItem('jobpanel-theme', theme);
        } catch (e) {}
    }
    
    function toggleTheme() {
        applyTheme(state.theme === 'dark' ? 'light' : 'dark');
    }
    window.toggleTheme = toggleTheme;
    
    // ===== Update Header =====
    function updateHeader(data) {
        setText('.brand-title', state.branding.title);
        setText('.brand-subtitle', state.branding.subtitle);
        setText('#jobName', formatJobName(data.job));
        setText('#jobRank', data.rankName || 'Rank');
        setText('#userName', data.playerName || L('unknown'));
        setText('#userRole', data.rankName || L('employee'));
        
        var avatar = document.getElementById('userAvatar');
        if (avatar) {
            avatar.innerHTML = '<span>' + getInitials(data.playerName) + '</span>';
        }
    }
    
    // ===== Permissions =====
    function applyPermissions() {
        var p = state.permissions;
        
        toggleDisabled('nav-employees', p.canViewEmployees === false);
        toggleDisabled('nav-salaries', !p.canEditSalaries);
        toggleDisabled('nav-ranks', !p.canManageRanks);
        toggleDisabled('nav-finances', !p.canViewFinances);
        toggleDisabled('nav-vehicles', !p.canOrderVehicles);
        toggleDisabled('nav-items', !p.canOrderItems);
        toggleDisabled('nav-logs', !p.canViewLogs);
        
        toggleHidden('btn-hire', !p.canHire);
        toggleHidden('quickHire', !p.canHire);
        toggleHidden('btn-fire-employee', !p.canFire);
    }
    
    // ===== Tab Navigation =====
    function switchTab(name) {
        var p = state.permissions;
        var allowed = {
            dashboard: true,
            employees: p.canViewEmployees !== false,
            salaries: p.canEditSalaries,
            ranks: p.canManageRanks,
            finances: p.canViewFinances,
            vehicles: p.canOrderVehicles,
            items: p.canOrderItems,
            logs: p.canViewLogs
        };
        
        if (!allowed[name]) {
            showToast('error', L('no_permission'));
            return;
        }
        
        // Update nav
        var navItems = document.querySelectorAll('.nav-item');
        for (var i = 0; i < navItems.length; i++) {
            navItems[i].classList.remove('active');
        }
        
        var activeNav = document.querySelector('[data-tab="' + name + '"]');
        if (activeNav) activeNav.classList.add('active');
        
        // Update content
        var tabs = document.querySelectorAll('.tab-content');
        for (var j = 0; j < tabs.length; j++) {
            tabs[j].classList.remove('active');
        }
        
        var activeTab = document.getElementById('tab-' + name);
        if (activeTab) activeTab.classList.add('active');
        
        // Update title
        var titleKey = 'nav_' + name;
        setText('#pageTitle', L(titleKey));
    }
    window.switchTab = switchTab;
    
    // ===== Custom Confirm Modal =====
    function showConfirm(title, message, confirmText, onConfirm, type) {
        var modal = document.getElementById('confirmModal');
        if (!modal) return;
        
        var icon = document.getElementById('confirmModalIcon');
        var titleEl = document.getElementById('confirmModalTitle');
        var msgEl = document.getElementById('confirmModalMessage');
        var btnEl = document.getElementById('confirmModalBtn');
        
        // Set type/color
        var iconClass = 'modal-icon ';
        var iconHtml = '<i class="fas fa-question-circle"></i>';
        
        if (type === 'danger' || type === 'fire') {
            iconClass += 'red';
            iconHtml = '<i class="fas fa-triangle-exclamation"></i>';
        } else if (type === 'success' || type === 'order') {
            iconClass += 'green';
            iconHtml = '<i class="fas fa-shopping-cart"></i>';
        } else {
            iconClass += 'blue';
            iconHtml = '<i class="fas fa-question-circle"></i>';
        }
        
        if (icon) {
            icon.className = iconClass;
            icon.innerHTML = iconHtml;
        }
        
        if (titleEl) titleEl.textContent = title;
        if (msgEl) msgEl.textContent = message;
        if (btnEl) {
            btnEl.innerHTML = '<i class="fas fa-check"></i> ' + confirmText;
            if (type === 'danger' || type === 'fire') {
                btnEl.className = 'btn btn-danger';
            } else {
                btnEl.className = 'btn btn-primary';
            }
        }
        
        state.pendingConfirm = onConfirm;
        modal.classList.remove('hidden');
    }
    
    function confirmAction() {
        if (state.pendingConfirm) {
            state.pendingConfirm();
            state.pendingConfirm = null;
        }
        closeModal('confirmModal');
    }
    window.confirmAction = confirmAction;
    
    // ===== Dashboard =====
    function renderDashboard() {
        var total = state.employees.length;
        var online = 0;
        var hours = 0;
        
        for (var i = 0; i < state.employees.length; i++) {
            if (state.employees[i].online) online++;
            hours += state.employees[i].hours || 0;
        }
        
        setText('#statTotalEmployees', String(total));
        setText('#statOnlineEmployees', String(online));
        setText('#statBalance', formatMoney(state.finances.balance));
        setText('#statHours', hours + 'h');
        setText('#employeeCount', String(total));
        setText('#onlineCountBadge', String(online));
        
        renderRecentActivity();
        renderOnlineStaff();
    }
    
    function renderRecentActivity() {
        var container = document.getElementById('recentActivity');
        if (!container) return;
        
        var logs = state.logs.slice(0, 5);
        
        if (logs.length === 0) {
            container.innerHTML = '<div class="empty-state"><p>' + L('no_activity') + '</p></div>';
            return;
        }
        
        var html = '';
        for (var i = 0; i < logs.length; i++) {
            var log = logs[i];
            html += '<div class="activity-item">' +
                '<div class="activity-icon ' + esc(log.type || '') + '"><i class="fas ' + getLogIcon(log.type) + '"></i></div>' +
                '<div class="activity-content">' +
                '<span class="activity-text">' + esc(log.message || '') + '</span>' +
                '<span class="activity-time">' + formatTime(log.timestamp) + '</span>' +
                '</div></div>';
        }
        container.innerHTML = html;
    }
    
    function renderOnlineStaff() {
        var container = document.getElementById('onlineStaffList');
        if (!container) return;
        
        var online = [];
        for (var i = 0; i < state.employees.length; i++) {
            if (state.employees[i].online) {
                online.push(state.employees[i]);
            }
        }
        
        if (online.length === 0) {
            container.innerHTML = '<div class="empty-state"><p>' + L('no_one_online') + '</p></div>';
            return;
        }
        
        var html = '';
        for (var j = 0; j < online.length; j++) {
            var emp = online[j];
            html += '<div class="online-staff-item">' +
                '<div class="staff-avatar">' + getInitials(emp.name) + '</div>' +
                '<div class="staff-info">' +
                '<span class="staff-name">' + esc(emp.name) + '</span>' +
                '<span class="staff-rank">' + esc(emp.rankName) + '</span>' +
                '</div><div class="staff-status"></div></div>';
        }
        container.innerHTML = html;
    }
    
    // ===== Employees =====
    function renderEmployees() {
        var container = document.getElementById('employeesGrid');
        if (!container) return;
        
        if (state.employees.length === 0) {
            container.innerHTML = '<div class="empty-state full-width"><p>' + L('no_employees') + '</p></div>';
            return;
        }
        
        var html = '';
        for (var i = 0; i < state.employees.length; i++) {
            var emp = state.employees[i];
            var statusClass = emp.online ? 'online' : 'offline';
            
            html += '<div class="employee-card" data-id="' + esc(emp.identifier) + '">' +
                '<div class="employee-card-header">' +
                '<div class="employee-avatar">' + getInitials(emp.name) +
                '<div class="employee-status-dot ' + statusClass + '"></div></div>' +
                '<div class="employee-info">' +
                '<div class="employee-name">' + esc(emp.name) + '</div>' +
                '<span class="employee-rank-badge">' + esc(emp.rankName) + '</span>' +
                '</div></div>' +
                '<div class="employee-card-body">' +
                '<div class="employee-stat"><span class="employee-stat-label">' + L('salary') + '</span>' +
                '<span class="employee-stat-value salary">' + formatMoney(emp.salary) + '</span></div>' +
                '<div class="employee-stat"><span class="employee-stat-label">' + L('hours') + '</span>' +
                '<span class="employee-stat-value">' + (emp.hours || 0) + 'h</span></div>' +
                '</div></div>';
        }
        container.innerHTML = html;
        
        // Add click handlers
        var cards = container.querySelectorAll('.employee-card');
        for (var j = 0; j < cards.length; j++) {
            cards[j].addEventListener('click', function() {
                var id = this.getAttribute('data-id');
                if (id) editEmployee(id);
            });
        }
    }
    
    function filterEmployees() {
        var input = document.getElementById('employeeSearch');
        var search = input ? input.value.toLowerCase() : '';
        var cards = document.querySelectorAll('.employee-card');
        
        for (var i = 0; i < cards.length; i++) {
            var name = cards[i].querySelector('.employee-name');
            var text = name ? name.textContent.toLowerCase() : '';
            cards[i].style.display = text.indexOf(search) !== -1 ? '' : 'none';
        }
    }
    window.filterEmployees = filterEmployees;
    
    function editEmployee(id) {
        var emp = findEmployee(id);
        if (!emp) return;
        
        setValue('editEmployeeId', id);
        setValue('editEmployeeName', emp.name);
        setValue('editEmployeeSalary', emp.individualSalary || '');
        
        var avatar = document.getElementById('editEmployeeAvatar');
        if (avatar) avatar.textContent = getInitials(emp.name);
        
        var select = document.getElementById('editEmployeeRank');
        if (select) {
            var html = '';
            for (var i = 0; i < state.ranks.length; i++) {
                var r = state.ranks[i];
                var sel = r.grade === emp.grade ? ' selected' : '';
                html += '<option value="' + r.grade + '"' + sel + '>' + esc(r.name) + '</option>';
            }
            select.innerHTML = html;
        }
        
        openModal('editEmployeeModal');
    }
    window.editEmployee = editEmployee;
    
    function saveEmployeeChanges() {
        postNUI('updateEmployee', {
            identifier: getValue('editEmployeeId'),
            grade: parseInt(getValue('editEmployeeRank')) || 0,
            individualSalary: parseInt(getValue('editEmployeeSalary')) || null
        });
        closeModal('editEmployeeModal');
        showToast('success', L('changes_saved'));
    }
    window.saveEmployeeChanges = saveEmployeeChanges;
    
    function fireEmployee() {
        var id = getValue('editEmployeeId');
        var name = getValue('editEmployeeName');
        
        showConfirm(
            L('fire'),
            L('confirm_fire') + ' ' + name + '?',
            L('fire'),
            function() {
                postNUI('fireEmployee', { identifier: id });
                closeModal('editEmployeeModal');
                showToast('success', L('person_fired'));
            },
            'danger'
        );
    }
    window.fireEmployee = fireEmployee;
    
    // ===== Hiring =====
    function openHireModal() {
        state.selectedPlayer = null;
        setValue('hirePlayerSearch', '');
        
        var select = document.getElementById('hireRank');
        if (select) {
            var html = '';
            for (var i = 0; i < state.ranks.length; i++) {
                html += '<option value="' + state.ranks[i].grade + '">' + esc(state.ranks[i].name) + '</option>';
            }
            select.innerHTML = html;
        }
        
        var nearbyList = document.getElementById('nearbyPlayersList');
        if (nearbyList) {
            nearbyList.innerHTML = '<p style="color:var(--text-muted);padding:10px;">' + L('searching_players') + '</p>';
        }
        
        postNUI('getNearbyPlayers', {});
        openModal('hireModal');
    }
    window.openHireModal = openHireModal;
    
    function renderNearbyPlayers(players) {
        var container = document.getElementById('nearbyPlayersList');
        if (!container) return;
        
        if (!players || players.length === 0) {
            container.innerHTML = '<p style="color:var(--text-muted);padding:10px;">' + L('no_nearby_players') + '</p>';
            return;
        }
        
        var html = '';
        for (var i = 0; i < players.length; i++) {
            var p = players[i];
            html += '<div class="nearby-player-item" data-id="' + p.id + '" data-name="' + esc(p.name) + '">' +
                '<div class="nearby-player-avatar">' + getInitials(p.name) + '</div>' +
                '<div class="nearby-player-info">' +
                '<div class="nearby-player-name">' + esc(p.name) + '</div>' +
                '<div class="nearby-player-id">ID: ' + p.id + '</div>' +
                '</div></div>';
        }
        container.innerHTML = html;
        
        // Add click handlers
        var items = container.querySelectorAll('.nearby-player-item');
        for (var j = 0; j < items.length; j++) {
            items[j].addEventListener('click', function() {
                var id = parseInt(this.getAttribute('data-id'));
                var name = this.getAttribute('data-name');
                
                state.selectedPlayer = id;
                setValue('hirePlayerSearch', name);
                
                var allItems = document.querySelectorAll('.nearby-player-item');
                for (var k = 0; k < allItems.length; k++) {
                    allItems[k].classList.remove('selected');
                }
                this.classList.add('selected');
            });
        }
    }
    
    function hirePlayer() {
        var input = getValue('hirePlayerSearch');
        var grade = parseInt(getValue('hireRank')) || 0;
        var playerId = state.selectedPlayer || parseInt(input);
        
        if (!playerId) {
            showToast('error', L('select_player'));
            return;
        }
        
        postNUI('hirePlayer', { playerId: playerId, grade: grade });
        closeModal('hireModal');
        showToast('success', L('player_hired'));
    }
    window.hirePlayer = hirePlayer;
    
    // ===== Salaries =====
    function renderSalaries() {
        var container = document.getElementById('rankSalariesGrid');
        if (container) {
            var html = '';
            for (var i = 0; i < state.ranks.length; i++) {
                var r = state.ranks[i];
                html += '<div class="salary-card">' +
                    '<div class="salary-card-header">' +
                    '<div class="salary-rank-info">' +
                    '<div class="salary-rank-badge">' + r.grade + '</div>' +
                    '<span class="salary-rank-name">' + esc(r.name) + '</span>' +
                    '</div></div>' +
                    '<div class="salary-input-group">' +
                    '<span class="input-prefix">$</span>' +
                    '<input type="number" class="salary-input" value="' + (r.salary || 0) + '" data-grade="' + r.grade + '">' +
                    '</div></div>';
            }
            container.innerHTML = html;
        }
        
        var bonus = document.getElementById('bonusEmployee');
        if (bonus) {
            var bhtml = '<option value="">' + L('select_recipient') + '</option>';
            for (var j = 0; j < state.employees.length; j++) {
                var e = state.employees[j];
                bhtml += '<option value="' + esc(e.identifier) + '">' + esc(e.name) + '</option>';
            }
            bonus.innerHTML = bhtml;
        }
    }
    
    function saveAllSalaries() {
        var inputs = document.querySelectorAll('#rankSalariesGrid .salary-input');
        var salaries = {};
        
        for (var i = 0; i < inputs.length; i++) {
            salaries[inputs[i].getAttribute('data-grade')] = parseInt(inputs[i].value) || 0;
        }
        
        postNUI('updateSalaries', { salaries: salaries });
        showToast('success', L('salaries_saved'));
    }
    window.saveAllSalaries = saveAllSalaries;
    
    function giveBonus() {
        var emp = getValue('bonusEmployee');
        var amount = parseInt(getValue('bonusAmount')) || 0;
        var reason = getValue('bonusReason');
        
        if (!emp) {
            showToast('error', L('select_recipient_error'));
            return;
        }
        if (amount <= 0) {
            showToast('error', L('enter_amount_error'));
            return;
        }
        
        postNUI('giveBonus', { employee: emp, amount: amount, reason: reason });
        setValue('bonusEmployee', '');
        setValue('bonusAmount', '');
        setValue('bonusReason', '');
        showToast('success', L('bonus_sent'));
    }
    window.giveBonus = giveBonus;
    
    // ===== Ranks =====
    function renderRanks() {
        var container = document.getElementById('ranksList');
        if (!container) return;
        
        if (state.ranks.length === 0) {
            container.innerHTML = '<div class="empty-state"><p>No ranks</p></div>';
            return;
        }
        
        var html = '';
        for (var i = 0; i < state.ranks.length; i++) {
            var r = state.ranks[i];
            html += '<div class="rank-item" data-grade="' + r.grade + '">' +
                '<div class="rank-grade-badge">' + r.grade + '</div>' +
                '<div class="rank-info">' +
                '<div class="rank-name">' + esc(r.name) + '</div>' +
                '<div class="rank-salary">' + formatMoney(r.salary) + L('per_day') + '</div>' +
                '</div>' +
                '<button class="btn btn-secondary rank-edit-btn" data-grade="' + r.grade + '">' +
                '<i class="fas fa-cog"></i> ' + L('edit') + '</button>' +
                '</div>';
        }
        container.innerHTML = html;
        
        // Add click handlers
        var buttons = container.querySelectorAll('.rank-edit-btn');
        for (var j = 0; j < buttons.length; j++) {
            buttons[j].addEventListener('click', function(e) {
                e.stopPropagation();
                var grade = parseInt(this.getAttribute('data-grade'));
                if (!isNaN(grade)) editRankPermissions(grade);
            });
        }
    }
    
    function editRankPermissions(grade) {
        var rank = findRank(grade);
        if (!rank) return;
        
        setValue('editRankGrade', String(grade));
        setValue('editRankName', rank.name);
        setValue('editRankSalary', String(rank.salary || 0));
        
        var perms = rank.permissions || {};
        var permList = [
            { key: 'canViewPanel', label: L('perm_view_panel') },
            { key: 'canViewEmployees', label: L('perm_view_employees') },
            { key: 'canViewFinances', label: L('perm_view_finances') },
            { key: 'canHire', label: L('perm_hire') },
            { key: 'canFire', label: L('perm_fire') },
            { key: 'canPromote', label: L('perm_promote') },
            { key: 'canEditSalaries', label: L('perm_edit_salaries') },
            { key: 'canOrderVehicles', label: L('perm_order_vehicles') },
            { key: 'canOrderItems', label: L('perm_order_items') },
            { key: 'canViewLogs', label: L('perm_view_logs') },
            { key: 'canManageRanks', label: L('perm_manage_ranks') }
        ];
        
        var grid = document.getElementById('permissionsGrid');
        if (grid) {
            var html = '';
            for (var i = 0; i < permList.length; i++) {
                var p = permList[i];
                var checked = perms[p.key] ? ' checked' : '';
                html += '<div class="permission-item">' +
                    '<input type="checkbox" id="perm-' + p.key + '"' + checked + '>' +
                    '<label for="perm-' + p.key + '">' + p.label + '</label></div>';
            }
            grid.innerHTML = html;
        }
        
        openModal('rankPermissionsModal');
    }
    window.editRankPermissions = editRankPermissions;
    
    function saveRankPermissions() {
        var permissions = {};
        var checks = document.querySelectorAll('#permissionsGrid input[type="checkbox"]');
        
        for (var i = 0; i < checks.length; i++) {
            var key = checks[i].id.replace('perm-', '');
            permissions[key] = checks[i].checked;
        }
        
        postNUI('updateRankPermissions', {
            grade: parseInt(getValue('editRankGrade')) || 0,
            name: getValue('editRankName'),
            salary: parseInt(getValue('editRankSalary')) || 0,
            permissions: permissions
        });
        
        closeModal('rankPermissionsModal');
        showToast('success', L('rank_updated'));
    }
    window.saveRankPermissions = saveRankPermissions;
    
    // ===== Finances =====
    function renderFinances() {
        setText('#financeBalance', formatMoney(state.finances.balance));
        
        var container = document.getElementById('transactionsList');
        if (!container) return;
        
        var txs = state.finances.transactions || [];
        if (txs.length === 0) {
            container.innerHTML = '<div class="empty-state"><p>' + L('no_transactions') + '</p></div>';
            return;
        }
        
        var html = '';
        for (var i = 0; i < txs.length; i++) {
            var tx = txs[i];
            var icon = tx.type === 'deposit' ? 'fa-arrow-down' : 'fa-arrow-up';
            var amtClass = tx.type === 'deposit' ? 'positive' : 'negative';
            var prefix = tx.type === 'deposit' ? '+' : '-';
            
            html += '<div class="transaction-item" data-type="' + (tx.type || '') + '">' +
                '<div class="transaction-icon ' + (tx.type || '') + '"><i class="fas ' + icon + '"></i></div>' +
                '<div class="transaction-info">' +
                '<div class="transaction-desc">' + esc(tx.description || tx.type || 'Transaction') + '</div>' +
                '<div class="transaction-meta">' + formatTime(tx.timestamp) + '</div></div>' +
                '<div class="transaction-amount ' + amtClass + '">' + prefix + formatMoney(tx.amount) + '</div></div>';
        }
        container.innerHTML = html;
    }
    
    function openDepositModal() {
        state.currentMoneyAction = 'deposit';
        
        var icon = document.getElementById('moneyModalIcon');
        if (icon) {
            icon.className = 'modal-icon green';
            icon.innerHTML = '<i class="fas fa-plus"></i>';
        }
        
        setText('#moneyModalTitle', L('deposit_title'));
        setText('#moneyModalSubtitle', L('deposit_subtitle'));
        setValue('moneyAmount', '');
        setValue('moneyReason', '');
        openModal('moneyModal');
    }
    window.openDepositModal = openDepositModal;
    
    function openWithdrawModal() {
        state.currentMoneyAction = 'withdraw';
        
        var icon = document.getElementById('moneyModalIcon');
        if (icon) {
            icon.className = 'modal-icon red';
            icon.innerHTML = '<i class="fas fa-minus"></i>';
        }
        
        setText('#moneyModalTitle', L('withdraw_title'));
        setText('#moneyModalSubtitle', L('withdraw_subtitle'));
        setValue('moneyAmount', '');
        setValue('moneyReason', '');
        openModal('moneyModal');
    }
    window.openWithdrawModal = openWithdrawModal;
    
    function confirmMoneyAction() {
        var amount = parseInt(getValue('moneyAmount')) || 0;
        if (amount <= 0) {
            showToast('error', L('invalid_amount'));
            return;
        }
        
        postNUI('societyMoney', {
            action: state.currentMoneyAction,
            amount: amount,
            reason: getValue('moneyReason')
        });
        
        closeModal('moneyModal');
        showToast('success', L('transaction_complete'));
    }
    window.confirmMoneyAction = confirmMoneyAction;
    
    // ===== Vehicles =====
    function renderVehicles() {
        var container = document.getElementById('vehiclesGrid');
        if (!container) return;
        
        if (state.vehicles.length === 0) {
            container.innerHTML = '<div class="empty-state full-width"><p>' + L('no_vehicles') + '</p></div>';
            return;
        }
        
        var html = '';
        for (var i = 0; i < state.vehicles.length; i++) {
            var v = state.vehicles[i];
            html += '<div class="vehicle-card" data-model="' + esc(v.model) + '" data-price="' + v.price + '" data-label="' + esc(v.label) + '">' +
                '<div class="vehicle-icon"><i class="fas fa-car-side"></i></div>' +
                '<div class="vehicle-name">' + esc(v.label) + '</div>' +
                '<div class="vehicle-price">' + formatMoney(v.price) + '</div>' +
                '<button class="btn btn-primary vehicle-order-btn">' +
                '<i class="fas fa-shopping-cart"></i> ' + L('order') + '</button></div>';
        }
        container.innerHTML = html;
        
        // Add click handlers
        var buttons = container.querySelectorAll('.vehicle-order-btn');
        for (var j = 0; j < buttons.length; j++) {
            buttons[j].addEventListener('click', function(e) {
                e.stopPropagation();
                var card = this.closest('.vehicle-card');
                var model = card.getAttribute('data-model');
                var price = parseInt(card.getAttribute('data-price'));
                var label = card.getAttribute('data-label');
                orderVehicle(model, price, label);
            });
        }
    }
    
    function orderVehicle(model, price, label) {
        showConfirm(
            L('order_vehicle'),
            L('confirm_order_vehicle') + ' ' + formatMoney(price) + '?',
            L('order'),
            function() {
                postNUI('orderVehicle', { model: model, price: price });
                showToast('success', L('vehicle_ordered'));
            },
            'order'
        );
    }
    window.orderVehicle = orderVehicle;
    
    // ===== Items & Cart =====
    function renderItems() {
        var container = document.getElementById('itemsGrid');
        if (!container) return;
        
        if (state.items.length === 0) {
            container.innerHTML = '<div class="empty-state full-width"><p>' + L('no_items') + '</p></div>';
            return;
        }
        
        var html = '';
        for (var i = 0; i < state.items.length; i++) {
            var item = state.items[i];
            html += '<div class="item-card" data-item="' + esc(item.item) + '" data-label="' + esc(item.label) + '" data-price="' + item.price + '">' +
                '<div class="item-icon"><i class="fas fa-box"></i></div>' +
                '<div class="item-name">' + esc(item.label) + '</div>' +
                '<div class="item-price">' + formatMoney(item.price) + '</div>' +
                '<button class="btn btn-primary item-add-btn">' +
                '<i class="fas fa-plus"></i> ' + L('add_to_cart') + '</button></div>';
        }
        container.innerHTML = html;
        
        // Add click handlers
        var buttons = container.querySelectorAll('.item-add-btn');
        for (var j = 0; j < buttons.length; j++) {
            buttons[j].addEventListener('click', function(e) {
                e.stopPropagation();
                var card = this.closest('.item-card');
                var itemId = card.getAttribute('data-item');
                var label = card.getAttribute('data-label');
                var price = parseInt(card.getAttribute('data-price'));
                addToCart(itemId, label, price);
            });
        }
    }
    
    function addToCart(itemId, label, price) {
        var found = false;
        for (var i = 0; i < state.cart.length; i++) {
            if (state.cart[i].item === itemId) {
                state.cart[i].quantity++;
                found = true;
                break;
            }
        }
        if (!found) {
            state.cart.push({ item: itemId, label: label, price: price, quantity: 1 });
        }
        renderCart();
        showToast('success', label + ' ' + L('item_added'));
    }
    window.addToCart = addToCart;
    
    function renderCart() {
        var container = document.getElementById('cartItems');
        var countEl = document.getElementById('cartCount');
        var totalEl = document.getElementById('cartTotal');
        
        var count = 0;
        var total = 0;
        for (var i = 0; i < state.cart.length; i++) {
            count += state.cart[i].quantity;
            total += state.cart[i].price * state.cart[i].quantity;
        }
        
        if (countEl) countEl.textContent = String(count);
        if (totalEl) totalEl.textContent = formatMoney(total);
        
        if (!container) return;
        
        if (state.cart.length === 0) {
            container.innerHTML = '<div class="cart-empty"><i class="fas fa-cart-shopping"></i><p>' + L('cart_empty') + '</p></div>';
            return;
        }
        
        var html = '';
        for (var j = 0; j < state.cart.length; j++) {
            var c = state.cart[j];
            html += '<div class="cart-item" data-index="' + j + '">' +
                '<div class="cart-item-info">' +
                '<span class="cart-item-qty">' + c.quantity + '</span>' +
                '<span class="cart-item-name">' + esc(c.label) + '</span></div>' +
                '<span class="cart-item-price">' + formatMoney(c.price * c.quantity) + '</span>' +
                '<button class="cart-item-remove">' +
                '<i class="fas fa-xmark"></i></button></div>';
        }
        container.innerHTML = html;
        
        // Add remove handlers
        var removeButtons = container.querySelectorAll('.cart-item-remove');
        for (var k = 0; k < removeButtons.length; k++) {
            removeButtons[k].addEventListener('click', function(e) {
                e.stopPropagation();
                var cartItem = this.closest('.cart-item');
                var index = parseInt(cartItem.getAttribute('data-index'));
                removeFromCart(index);
            });
        }
    }
    
    function removeFromCart(index) {
        if (index < 0 || index >= state.cart.length) return;
        
        if (state.cart[index].quantity > 1) {
            state.cart[index].quantity--;
        } else {
            state.cart.splice(index, 1);
        }
        renderCart();
    }
    window.removeFromCart = removeFromCart;
    
    function placeOrder() {
        if (state.cart.length === 0) {
            showToast('error', L('cart_empty'));
            return;
        }
        
        var total = 0;
        for (var i = 0; i < state.cart.length; i++) {
            total += state.cart[i].price * state.cart[i].quantity;
        }
        
        showConfirm(
            L('confirm_order'),
            L('confirm_order_items') + ' ' + state.cart.length + ' ' + L('items_for') + ' ' + formatMoney(total) + '?',
            L('place_order'),
            function() {
                postNUI('orderItems', { items: state.cart });
                state.cart = [];
                renderCart();
                showToast('success', L('order_placed'));
            },
            'order'
        );
    }
    window.placeOrder = placeOrder;
    
    // ===== Logs =====
    function renderLogs() {
        var container = document.getElementById('logsTimeline');
        if (!container) return;
        
        if (!state.logs || state.logs.length === 0) {
            container.innerHTML = '<div class="empty-state"><i class="fas fa-scroll"></i><p>' + L('no_logs') + '</p></div>';
            return;
        }
        
        var html = '';
        for (var i = 0; i < state.logs.length; i++) {
            var log = state.logs[i];
            var logType = log.type || 'info';
            var logMessage = log.message || '';
            var logBy = log.by || 'System';
            
            html += '<div class="log-item" data-type="' + esc(logType) + '">' +
                '<div class="log-icon ' + esc(logType) + '">' +
                '<i class="fas ' + getLogIcon(logType) + '"></i>' +
                '</div>' +
                '<div class="log-content">' +
                '<div class="log-message">' + esc(logMessage) + '</div>' +
                '<div class="log-meta">' + formatTime(log.timestamp) + ' • ' + esc(logBy) + '</div>' +
                '</div>' +
                '</div>';
        }
        
        container.innerHTML = html;
    }
    
    function filterLogs() {
        var select = document.getElementById('logTypeFilter');
        var filter = select ? select.value : 'all';
        var items = document.querySelectorAll('.log-item');
        
        for (var i = 0; i < items.length; i++) {
            var itemType = items[i].getAttribute('data-type');
            if (filter === 'all' || itemType === filter) {
                items[i].style.display = '';
            } else {
                items[i].style.display = 'none';
            }
        }
    }
    window.filterLogs = filterLogs;
    
    // ===== Modals =====
    function openModal(id) {
        var modal = document.getElementById(id);
        if (modal) modal.classList.remove('hidden');
    }
    window.openModal = openModal;
    
    function closeModal(id) {
        var modal = document.getElementById(id);
        if (modal) modal.classList.add('hidden');
    }
    window.closeModal = closeModal;
    
    function closeAllModals() {
        var modals = document.querySelectorAll('.modal-overlay');
        for (var i = 0; i < modals.length; i++) {
            modals[i].classList.add('hidden');
        }
    }
    
    // ===== Toast =====
    function showToast(type, message) {
        var container = document.getElementById('toastContainer');
        if (!container) return;
        
        var icons = {
            success: 'fa-check',
            error: 'fa-xmark',
            warning: 'fa-exclamation',
            info: 'fa-info'
        };
        
        var toast = document.createElement('div');
        toast.className = 'toast ' + type;
        toast.innerHTML = '<div class="toast-icon"><i class="fas ' + (icons[type] || 'fa-info') + '"></i></div>' +
            '<div class="toast-content"><div class="toast-message">' + esc(message) + '</div></div>' +
            '<button class="toast-close"><i class="fas fa-xmark"></i></button>';
        
        container.appendChild(toast);
        
        // Close button handler
        var closeBtn = toast.querySelector('.toast-close');
        if (closeBtn) {
            closeBtn.addEventListener('click', function() {
                toast.remove();
            });
        }
        
        // Auto remove
        setTimeout(function() {
            if (toast.parentElement) toast.remove();
        }, 4000);
    }
    
    // ===== Refresh =====
    function refreshData() {
        postNUI('refreshData', {});
        showToast('info', L('updating'));
    }
    window.refreshData = refreshData;
    
    // ===== Sidebar =====
    function toggleSidebar() {
        var sidebar = document.querySelector('.sidebar');
        if (sidebar) sidebar.classList.toggle('open');
    }
    window.toggleSidebar = toggleSidebar;
    
    function toggleUserMenu() {
        showToast('info', L('coming_soon'));
    }
    window.toggleUserMenu = toggleUserMenu;
    
    // ===== Helpers =====
    function findEmployee(id) {
        for (var i = 0; i < state.employees.length; i++) {
            if (state.employees[i].identifier === id) return state.employees[i];
        }
        return null;
    }
    
    function findRank(grade) {
        for (var i = 0; i < state.ranks.length; i++) {
            if (state.ranks[i].grade === grade) return state.ranks[i];
        }
        return null;
    }
    
    function esc(str) {
        if (str === null || str === undefined) return '';
        var text = String(str);
        var div = document.createElement('div');
        div.textContent = text;
        return div.innerHTML;
    }
    
    function setText(selector, text) {
        var el;
        if (selector.charAt(0) === '#') {
            el = document.getElementById(selector.substring(1));
        } else if (selector.charAt(0) === '.') {
            el = document.querySelector(selector);
        } else {
            el = document.getElementById(selector);
        }
        if (el) el.textContent = (text !== null && text !== undefined) ? text : '';
    }
    
    function getValue(id) {
        var el = document.getElementById(id);
        return el ? el.value : '';
    }
    
    function setValue(id, val) {
        var el = document.getElementById(id);
        if (el) el.value = (val !== null && val !== undefined) ? val : '';
    }
    
    function toggleDisabled(id, disabled) {
        var el = document.getElementById(id);
        if (el) {
            if (disabled) {
                el.classList.add('disabled');
            } else {
                el.classList.remove('disabled');
            }
        }
    }
    
    function toggleHidden(id, hidden) {
        var el = document.getElementById(id);
        if (el) el.style.display = hidden ? 'none' : '';
    }
    
    function formatMoney(amount) {
        var num = parseInt(amount) || 0;
        return '$' + num.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ' ');
    }
    
    function formatJobName(job) {
        if (!job) return L('job_unknown');
        var key = 'job_' + job;
        var translated = L(key);
        if (translated !== key) return translated;
        return job.charAt(0).toUpperCase() + job.slice(1);
    }
    
    function formatTime(ts) {
        if (!ts) return '';
        try {
            var date = new Date(ts);
            if (isNaN(date.getTime())) return '';
            
            var now = new Date();
            var diff = Math.floor((now - date) / 1000);
            
            if (diff < 60) return L('now');
            if (diff < 3600) return Math.floor(diff / 60) + ' ' + L('min_ago');
            if (diff < 86400) return Math.floor(diff / 3600) + ' ' + L('hours_ago');
            return Math.floor(diff / 86400) + ' ' + L('days_ago');
        } catch (e) {
            return '';
        }
    }
    
    function getInitials(name) {
        if (!name) return '?';
        var parts = String(name).trim().split(' ');
        var initials = '';
        for (var i = 0; i < Math.min(2, parts.length); i++) {
            if (parts[i].length > 0) {
                initials += parts[i].charAt(0).toUpperCase();
            }
        }
        return initials || '?';
    }
    
    function getLogIcon(type) {
        var icons = {
            hire: 'fa-user-plus',
            fire: 'fa-user-minus',
            promote: 'fa-arrow-up',
            salary: 'fa-dollar-sign',
            finance: 'fa-wallet',
            deposit: 'fa-arrow-down',
            withdraw: 'fa-arrow-up'
        };
        return icons[type] || 'fa-circle-info';
    }
    
    console.log('[JobPanel] Script loaded');
    
})();