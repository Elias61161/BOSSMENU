Locales = Locales or {}

Locales['en'] = {
    -- General
    ['loading'] = 'Loading...',
    ['close'] = 'Close',
    ['save'] = 'Save',
    ['cancel'] = 'Cancel',
    ['confirm'] = 'Confirm',
    ['delete'] = 'Delete',
    ['edit'] = 'Edit',
    ['search'] = 'Search...',
    ['no_permission'] = 'You do not have permission',
    ['success'] = 'Success',
    ['error'] = 'Error',
    ['warning'] = 'Warning',
    ['info'] = 'Information',
    
    -- Navigation
    ['nav_dashboard'] = 'Dashboard',
    ['nav_employees'] = 'Employees',
    ['nav_salaries'] = 'Salaries',
    ['nav_ranks'] = 'Ranks',
    ['nav_finances'] = 'Finances',
    ['nav_vehicles'] = 'Vehicles',
    ['nav_items'] = 'Equipment',
    ['nav_logs'] = 'Logs',
    
    -- Dashboard
    ['dashboard_welcome'] = 'Welcome back!',
    ['dashboard_subtitle'] = 'Here is an overview of your job.',
    ['total_employees'] = 'Total Employees',
    ['online_now'] = 'Online Now',
    ['company_balance'] = 'Company Balance',
    ['hours_this_week'] = 'Hours This Week',
    ['quick_actions'] = 'Quick Actions',
    ['recent_activity'] = 'Recent Activity',
    ['staff_online'] = 'Staff Online',
    ['no_activity'] = 'No activity',
    ['no_one_online'] = 'No one online',
    
    -- Employees
    ['employees_title'] = 'Employee Management',
    ['employees_subtitle'] = 'Manage employees and their information.',
    ['hire'] = 'Hire',
    ['fire'] = 'Fire',
    ['promote'] = 'Promote',
    ['salary'] = 'Salary',
    ['hours'] = 'Hours',
    ['status_online'] = 'Online',
    ['status_offline'] = 'Offline',
    ['all'] = 'All',
    ['no_employees'] = 'No employees',
    
    -- Hiring
    ['hire_title'] = 'Hire Employee',
    ['hire_subtitle'] = 'Add a new team member',
    ['player_id_name'] = 'Player ID or Name',
    ['select_rank'] = 'Select Rank',
    ['nearby_players'] = 'Nearby Players',
    ['searching_players'] = 'Searching players...',
    ['no_nearby_players'] = 'No players nearby',
    ['select_player'] = 'Select a player',
    ['player_hired'] = 'Player hired',
    
    -- Edit employee
    ['edit_employee'] = 'Edit Employee',
    ['edit_employee_subtitle'] = 'Change information and permissions',
    ['individual_salary'] = 'Individual Salary',
    ['individual_salary_hint'] = 'Leave empty for default salary',
    ['changes_saved'] = 'Changes saved',
    ['person_fired'] = 'Person fired',
    ['confirm_fire'] = 'Are you sure you want to fire',
    
    -- Salaries
    ['salaries_title'] = 'Salary Management',
    ['salaries_subtitle'] = 'Manage salaries and bonuses.',
    ['rank_salaries'] = 'Rank Salaries',
    ['rank_salaries_desc'] = 'Manage default salaries for each rank',
    ['save_changes'] = 'Save Changes',
    ['salaries_saved'] = 'Salaries saved',
    ['give_bonus'] = 'Give Bonus',
    ['give_bonus_desc'] = 'Send a one-time bonus',
    ['select_recipient'] = 'Select recipient...',
    ['amount'] = 'Amount',
    ['reason'] = 'Reason',
    ['send_bonus'] = 'Send Bonus',
    ['bonus_sent'] = 'Bonus sent',
    ['select_recipient_error'] = 'Select a recipient',
    ['enter_amount_error'] = 'Enter a valid amount',
    
    -- Ranks
    ['ranks_title'] = 'Rank Management',
    ['ranks_subtitle'] = 'Configure ranks and permissions.',
    ['rank_updated'] = 'Rank updated',
    ['edit_rank'] = 'Edit Rank',
    ['edit_rank_subtitle'] = 'Configure permissions',
    ['rank_name'] = 'Rank Name',
    ['default_salary'] = 'Default Salary',
    ['permissions'] = 'Permissions',
    
    -- Permissions
    ['perm_view_panel'] = 'View Job Panel',
    ['perm_view_employees'] = 'View Employees',
    ['perm_view_finances'] = 'View Finances',
    ['perm_hire'] = 'Hire',
    ['perm_fire'] = 'Fire',
    ['perm_promote'] = 'Promote',
    ['perm_edit_salaries'] = 'Edit Salaries',
    ['perm_order_vehicles'] = 'Order Vehicles',
    ['perm_order_items'] = 'Order Equipment',
    ['perm_view_logs'] = 'View Logs',
    ['perm_manage_ranks'] = 'Manage Ranks',
    
    -- Finances
    ['finances_title'] = 'Financial Overview',
    ['finances_subtitle'] = 'Overview of company finances.',
    ['deposit'] = 'Deposit',
    ['withdraw'] = 'Withdraw',
    ['deposit_title'] = 'Deposit Money',
    ['deposit_subtitle'] = 'Transfer to company account',
    ['withdraw_title'] = 'Withdraw Money',
    ['withdraw_subtitle'] = 'Withdraw from company account',
    ['transaction_complete'] = 'Transaction complete',
    ['invalid_amount'] = 'Enter a valid amount',
    ['transactions'] = 'Transactions',
    ['no_transactions'] = 'No transactions',
    ['deposits'] = 'Deposits',
    ['withdrawals'] = 'Withdrawals',
    
    -- Vehicles
    ['vehicles_title'] = 'Vehicle Orders',
    ['vehicles_subtitle'] = 'Order new vehicles for the organization.',
    ['order'] = 'Order',
    ['order_vehicle'] = 'Order Vehicle',
    ['confirm_order_vehicle'] = 'Do you want to order this vehicle for',
    ['vehicle_ordered'] = 'Vehicle ordered',
    ['no_vehicles'] = 'No vehicles available',
    
    -- Items
    ['items_title'] = 'Equipment Orders',
    ['items_subtitle'] = 'Order equipment and supplies.',
    ['add_to_cart'] = 'Add',
    ['cart'] = 'Cart',
    ['cart_empty'] = 'Cart is empty',
    ['total'] = 'Total',
    ['place_order'] = 'Place Order',
    ['confirm_order'] = 'Confirm Order',
    ['confirm_order_items'] = 'Do you want to order',
    ['items_for'] = 'items for',
    ['order_placed'] = 'Order placed',
    ['item_added'] = 'added to cart',
    ['no_items'] = 'No equipment available',
    
    -- Logs
    ['logs_title'] = 'Activity Log',
    ['logs_subtitle'] = 'View all activity in the organization.',
    ['all_events'] = 'All events',
    ['hires'] = 'Hires',
    ['fires'] = 'Fires',
    ['promotions'] = 'Promotions',
    ['salary_changes'] = 'Salary changes',
    ['financial'] = 'Financial',
    ['no_logs'] = 'No logs to display',
    
    -- Time format
    ['now'] = 'Now',
    ['min_ago'] = 'min ago',
    ['hours_ago'] = 'hours ago',
    ['days_ago'] = 'days ago',
    
    -- Jobs
    ['job_police'] = 'Police',
    ['job_ambulance'] = 'Medical',
    ['job_mechanic'] = 'Mechanics',
    ['job_taxi'] = 'Taxi',
    ['job_unknown'] = 'Job',
    
    -- Theme
    ['dark_mode'] = 'Dark mode',
    ['light_mode'] = 'Light mode',
    
    -- Other
    ['per_day'] = '/day',
    ['updating'] = 'Updating...',
    ['coming_soon'] = 'Coming soon'
}