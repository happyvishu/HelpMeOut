// Auto-refresh page every 5 minutes to check if maintenance is complete
const AUTO_REFRESH_INTERVAL = 5 * 60 * 1000; // 5 minutes in milliseconds

// Display current time
function updateCurrentTime() {
    const now = new Date();
    const timeString = now.toLocaleString('en-US', {
        month: 'short',
        day: 'numeric',
        year: 'numeric',
        hour: '2-digit',
        minute: '2-digit',
        hour12: true
    });
    
    // You can add a time display element if needed
    console.log('Current time:', timeString);
}

// Initialize
document.addEventListener('DOMContentLoaded', function() {
    updateCurrentTime();
    
    // Set up auto-refresh
    setTimeout(() => {
        location.reload();
    }, AUTO_REFRESH_INTERVAL);
    
    // Add smooth scroll behavior
    document.documentElement.style.scrollBehavior = 'smooth';
    
    // Log maintenance mode
    console.log('%c🔧 Maintenance Mode Active', 'font-size: 20px; font-weight: bold; color: #667eea;');
    console.log('%cPage will auto-refresh in 5 minutes', 'font-size: 14px; color: #888;');
});

// Add keyboard shortcut to manually refresh (Ctrl/Cmd + R is default, but let's add F5 handling)
document.addEventListener('keydown', function(e) {
    if (e.key === 'F5') {
        e.preventDefault();
        location.reload();
    }
});

// Optional: Add a countdown timer
let remainingTime = AUTO_REFRESH_INTERVAL / 1000; // in seconds

function updateCountdown() {
    remainingTime--;
    
    if (remainingTime <= 0) {
        location.reload();
    }
    
    // You can display this countdown if you add a DOM element for it
    const minutes = Math.floor(remainingTime / 60);
    const seconds = remainingTime % 60;
    console.log(`Next refresh in: ${minutes}:${seconds.toString().padStart(2, '0')}`);
}

// Update countdown every second
setInterval(updateCountdown, 1000);
