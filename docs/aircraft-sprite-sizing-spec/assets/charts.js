(function () {
  var style = getComputedStyle(document.documentElement);
  var accent = style.getPropertyValue('--accent').trim();
  var accent2 = style.getPropertyValue('--accent2').trim();
  var ink = style.getPropertyValue('--ink').trim();
  var muted = style.getPropertyValue('--muted').trim();
  var rule = style.getPropertyValue('--rule').trim();

  var aircraft = [
    { name: "J8M 秋水", w: 86, h: 54, canvas: 128, type: "战斗机" },
    { name: "Ki-27 九七战", w: 102, h: 68, canvas: 128, type: "战斗机" },
    { name: "Ki-44 钟馗", w: 86, h: 80, canvas: 128, type: "战斗机" },
    { name: "Ki-43 隼", w: 97, h: 80, canvas: 128, type: "战斗机" },
    { name: "A6M 零式", w: 99, h: 82, canvas: 128, type: "战斗机" },
    { name: "Ki-61 飞燕", w: 108, h: 80, canvas: 128, type: "战斗机" },
    { name: "Ki-100 五式战", w: 108, h: 80, canvas: 128, type: "战斗机" },
    { name: "J2M 雷电", w: 97, h: 87, canvas: 128, type: "战斗机" },
    { name: "J7W 震电", w: 101, h: 88, canvas: 128, type: "战斗机" },
    { name: "Ki-84 疾风", w: 101, h: 89, canvas: 128, type: "战斗机" },
    { name: "Ki-51 攻击机", w: 109, h: 83, canvas: 128, type: "攻击机" },
    { name: "D3A 九九舰爆", w: 129, h: 92, canvas: 192, type: "俯冲轰炸机" },
    { name: "Ki-45 屠龙", w: 135, h: 99, canvas: 192, type: "重型战斗机" },
    { name: "Ki-102 五式复座", w: 140, h: 104, canvas: 192, type: "重型战斗机" },
    { name: "Ki-48 九九轻爆", w: 158, h: 116, canvas: 192, type: "轻型轰炸机" },
    { name: "Ki-49 百式重爆", w: 184, h: 151, canvas: 256, type: "重型轰炸机" },
    { name: "Ki-21 九七重爆", w: 202, h: 148, canvas: 256, type: "重型轰炸机" },
    { name: "Ki-67 飞龙", w: 202, h: 168, canvas: 256, type: "中型轰炸机" },
    { name: "G3M 九六陆攻", w: 225, h: 148, canvas: 256, type: "陆攻轰炸机" },
    { name: "G4M 一式陆攻", w: 225, h: 180, canvas: 256, type: "陆攻轰炸机" },
    { name: "G8N 连山", w: 288, h: 206, canvas: 384, type: "重型轰炸机" }
  ];

  // Chart 1: Wingspan comparison (horizontal bar)
  var chart1 = echarts.init(document.getElementById('chart-wingspan'));
  chart1.setOption({
    title: { text: '各机型翼展像素宽度对比（9px/m）', left: 'center', textStyle: { color: ink, fontSize: 14 } },
    tooltip: { trigger: 'axis', axisPointer: { type: 'shadow' },
      formatter: function (p) {
        var d = aircraft[p[0].dataIndex];
        return d.name + '<br/>翼展: ' + d.w + 'px<br/>机身: ' + d.h + 'px<br/>画布: ' + d.canvas + '×' + d.canvas;
      }
    },
    grid: { left: '18%', right: '8%', top: 50, bottom: 30 },
    xAxis: { type: 'value', name: '翼展 (px)', nameTextStyle: { color: muted }, axisLabel: { color: muted }, splitLine: { lineStyle: { color: rule } } },
    yAxis: { type: 'category', data: aircraft.map(function (a) { return a.name; }),
      axisLabel: { color: ink, fontSize: 11 },
      axisLine: { lineStyle: { color: rule } }
    },
    series: [{
      type: 'bar',
      data: aircraft.map(function (a) { return a.w; }),
      itemStyle: {
        color: function (params) {
          var c = aircraft[params.dataIndex].canvas;
          if (c <= 128) return accent;
          if (c <= 192) return '#d4a017';
          if (c <= 256) return '#e67e22';
          return accent2;
        }
      },
      label: { show: true, position: 'right', color: muted, fontSize: 10, formatter: '{c}px' }
    }]
  });

  // Chart 2: Canvas tier distribution (scatter: wingspan vs length)
  var chart2 = echarts.init(document.getElementById('chart-scatter'));
  var groups = {};
  aircraft.forEach(function (a) {
    var key = a.canvas;
    if (!groups[key]) groups[key] = [];
    groups[key].push(a);
  });
  var palette = { 128: accent, 192: '#d4a017', 256: '#e67e22', 384: accent2 };
  var series = Object.keys(groups).map(function (key) {
    return {
      name: key + '×' + key,
      type: 'scatter',
      symbolSize: function (data) { return Math.max(8, data[0] / 6); },
      data: groups[key].map(function (a) { return [a.w, a.h, a.name]; }),
      itemStyle: { color: palette[key] || muted, opacity: 0.8 }
    };
  });
  chart2.setOption({
    title: { text: '翼展 × 机身长度 散点分布（点大小 ∝ 翼展）', left: 'center', textStyle: { color: ink, fontSize: 14 } },
    tooltip: {
      trigger: 'item',
      formatter: function (p) { return p.data[2] + '<br/>翼展: ' + p.data[0] + 'px<br/>机身: ' + p.data[1] + 'px'; }
    },
    legend: { bottom: 5, textStyle: { color: muted, fontSize: 11 } },
    grid: { left: '10%', right: '8%', top: 50, bottom: 60 },
    xAxis: { type: 'value', name: '翼展 (px)', nameTextStyle: { color: muted }, axisLabel: { color: muted }, splitLine: { lineStyle: { color: rule } } },
    yAxis: { type: 'value', name: '机身 (px)', nameTextStyle: { color: muted }, axisLabel: { color: muted }, splitLine: { lineStyle: { color: rule } } },
    series: series
  });

  window.addEventListener('resize', function () {
    chart1.resize();
    chart2.resize();
  });
})();
