import Chart from 'chart.js/auto';

const ChartHook = {
  mounted() {
    this.handleEvent('update-chart', (data) => {
      console.log('update-chart', data);
      const now = new Date();
      const timeString = now.toLocaleTimeString('en-US', {
        hour: '2-digit',
        minute: '2-digit',
        second: '2-digit',
        hour12: false,
      });

      const memory = Number(data.memory);
      const totalHeapSize = Number(data.total_heap_size);
      const heapSize = Number(data.heap_size);
      const stackSize = Number(data.stack_size);

      this.chart.data.labels.push(timeString);
      this.chart.data.datasets[0].data.push(Number(memory));
      this.chart.data.datasets[1].data.push(Number(totalHeapSize));
      this.chart.data.datasets[2].data.push(Number(heapSize));
      this.chart.data.datasets[3].data.push(Number(stackSize));

      if (this.chart.data.labels.length > 50) {
        this.chart.data.labels.shift();
        this.chart.data.datasets[0].data.shift();
        this.chart.data.datasets[1].data.shift();
        this.chart.data.datasets[2].data.shift();
        this.chart.data.datasets[3].data.shift();
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
          {
            label: 'Total Heap Size',
            backgroundColor: code4,
            borderColor: code4,
            data: [],
          },
          {
            label: 'Heap Size',
            backgroundColor: code4,
            borderColor: code4,
            data: [],
          },
          {
            label: 'Stack Size',
            backgroundColor: code4,
            borderColor: code4,
            data: [],
          },
        ],
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        animation: false,
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
