import Chart from 'chart.js/auto';

const ChartHook = {
  mounted() {
    const style = getComputedStyle(document.documentElement);
    const code4 = style.getPropertyValue('--code-4').trim();
    const primaryText = style.getPropertyValue('--primary-text').trim();
    const defaultBorder = style.getPropertyValue('--default-border').trim();

    new Chart(this.el, {
      type: 'line',
      data: {
        labels: [
          'January',
          'February',
          'March',
          'April',
          'May',
          'June',
          'July',
        ],
        datasets: [
          {
            label: 'My First dataset',
            backgroundColor: code4,
            borderColor: code4,
            data: [0, 10, 5, 2, 20, 30, 45],
          },
        ],
      },
      options: {
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
