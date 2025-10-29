import Chart from 'chart.js/auto';

const ChartHook = {
  mounted() {
    this.handleEvent('update-chart', ({ value, key }) => {
      const now = new Date();
      const timeString = now.toLocaleTimeString('en-US', {
        hour: '2-digit',
        minute: '2-digit',
        second: '2-digit',
        hour12: false,
      });

      this.chart.data.labels.push(timeString);
      this.chart.data.datasets[0].data.push(Number(value));

      if (this.chart.data.labels.length > 50) {
        this.chart.data.labels.shift();
        this.chart.data.datasets[0].data.shift();
      }

      this.chart.update('none');
    });
    const style = getComputedStyle(document.documentElement);
    const code4 = style.getPropertyValue('--code-4').trim();
    const primaryText = style.getPropertyValue('--primary-text').trim();
    const defaultBorder = style.getPropertyValue('--default-border').trim();

    this.chart = new Chart(this.el, {
      type: 'line',
      data: {
        labels: [],
        datasets: [
          {
            label: 'Memory',
            backgroundColor: code4,
            borderColor: code4,
            data: [],
          },
        ],
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: {
            labels: {
              color: primaryText,
            },
          },
        },
        scales: {
          x: {
            ticks: {
              color: primaryText,
            },
            grid: {
              color: defaultBorder,
            },
          },
          y: {
            ticks: {
              color: primaryText,
            },
            grid: {
              color: defaultBorder,
            },
          },
        },
      },
    });
  },
};

export default ChartHook;
