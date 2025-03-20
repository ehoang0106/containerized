let chart;

function showLoading() {
    document.getElementById('loadingIndicator').style.display = 'block';
    document.getElementById('errorMessage').style.display = 'none';
}

function hideLoading() {
    document.getElementById('loadingIndicator').style.display = 'none';
}

function showError(message) {
    const errorElement = document.getElementById('errorMessage');
    errorElement.textContent = message;
    errorElement.style.display = 'block';
    document.getElementById('statusIndicator').classList.add('error');
}

function clearError() {
    document.getElementById('errorMessage').style.display = 'none';
    document.getElementById('statusIndicator').classList.remove('error');
}

async function fetchData() {
    showLoading();
    try {
        const response = await fetch('/api/data');
        if (!response.ok) {
            throw new Error('Failed to fetch data');
        }
        const data = await response.json();
        updateDisplay(data);
        clearError();
    } catch (error) {
        console.error('Error fetching data:', error);
        showError('Error loading price data. Please try again.');
    } finally {
        hideLoading();
    }
}

async function updateData() {
    showLoading();
    try {
        const response = await fetch('/api/update');
        if (!response.ok) {
            throw new Error('Failed to update data');
        }
        const data = await response.json();
        if (data.status === 'success') {
            fetchData();
        }
    } catch (error) {
        console.error('Error updating data:', error);
        showError('Error updating price data. Please try again.');
    } finally {
        hideLoading();
    }
}

function updateDisplay(data) {
    if (data.prices && data.prices.length > 0) {
        const latestPrice = data.prices[data.prices.length - 1];
        document.getElementById('currentPrice').textContent = 
            `${latestPrice.toLocaleString()} exalted`;
    }
    
    updateChart(data);
    
    if (data.labels && data.labels.length > 0) {
        const lastUpdateTime = data.labels[data.labels.length - 1];
        const updateTime = new Date(lastUpdateTime);
        const formattedTime = updateTime.toLocaleString('en-US', {
            year: 'numeric',
            month: '2-digit',
            day: '2-digit',
            hour: '2-digit',
            minute: '2-digit',
            hour12: true
        });
        document.getElementById('lastUpdate').textContent = 
            `Last Update: ${formattedTime}`;
    }
}

function updateChart(data) {
    if (chart) {
        chart.destroy();
    }

    const ctx = document.getElementById('priceChart').getContext('2d');
    chart = new Chart(ctx, {
        type: 'line',
        data: {
            labels: data.labels,
            datasets: [
                {
                    label: 'Price (exalted)',
                    data: data.prices,
                    borderColor: 'rgb(75, 192, 192)',
                    tension: 0.1,
                    fill: false
                }
            ]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            scales: {
                y: {
                    beginAtZero: false,
                    title: {
                        display: true,
                        text: 'Price (exalted)'
                    }
                },
                x: {
                    title: {
                        display: true,
                        text: 'Time'
                    }
                }
            },
            plugins: {
                title: {
                    display: true,
                    text: 'Divine Orb Price Over Time'
                }
            }
        }
    });
}

// Initial data fetch
fetchData();
// Update every 2 minutes
setInterval(fetchData, 120000); 