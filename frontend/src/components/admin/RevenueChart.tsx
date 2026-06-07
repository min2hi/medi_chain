'use client';

import { Transaction } from '@/services/staff.service';

interface RevenueChartProps {
  transactions: Transaction[];
  height?: number;
  viewBox?: string;
  gridYMax?: number;
}

export function RevenueChart({ transactions, height = 140, viewBox = "0 0 500 140", gridYMax = 110 }: RevenueChartProps) {
  // Get last 7 days (including today)
  const last7Days = Array.from({ length: 7 }, (_, i) => {
    const d = new Date();
    d.setDate(d.getDate() - (6 - i));
    return d;
  });

  // Calculate daily revenue
  const dailyData = last7Days.map(day => {
    const dateStr = day.toLocaleDateString('en-CA'); // 'YYYY-MM-DD'
    const total = transactions
      .filter(t => t.status === 'PAID' && new Date(t.date).toLocaleDateString('en-CA') === dateStr)
      .reduce((sum, t) => sum + t.amount, 0);
    return {
      dateLabel: `${day.getDate()}/${day.getMonth() + 1}`,
      value: total
    };
  });

  const maxVal = Math.max(...dailyData.map(d => d.value), 10000); // Fallback to 10k

  // Calculate SVG points: width 500
  // paddingLeft: 50, paddingRight: 20, paddingTop: 20, paddingBottom: 25
  // chartWidth = 430, chartHeight = gridYMax - 30
  const chartHeight = gridYMax - 30;
  const points = dailyData.map((d, i) => {
    const x = 50 + (i / 6) * 430;
    const y = gridYMax - (d.value / maxVal) * chartHeight;
    return { x, y };
  });

  let linePath = '';
  if (points.length > 0) {
    linePath = `M ${points[0].x} ${points[0].y}`;
    for (let i = 0; i < points.length - 1; i++) {
      const p1 = points[i];
      const p2 = points[i + 1];
      const c1x = p1.x + (p2.x - p1.x) / 2;
      const c1y = p1.y;
      const c2x = p1.x + (p2.x - p1.x) / 2;
      const c2y = p2.y;
      linePath += ` C ${c1x} ${c1y}, ${c2x} ${c2y}, ${p2.x} ${p2.y}`;
    }
  }

  const fillPath = points.length > 0 
    ? `${linePath} L ${points[points.length - 1].x} ${gridYMax} L ${points[0].x} ${gridYMax} Z` 
    : '';

  const gridLines = [
    { y: gridYMax, value: 0 },
    { y: gridYMax - (chartHeight / 3) * 1, value: (maxVal / 3) * 1 },
    { y: gridYMax - (chartHeight / 3) * 2, value: (maxVal / 3) * 2 },
    { y: 30, value: maxVal },
  ];

  return (
    <div className="w-full overflow-hidden">
      <svg viewBox={viewBox} className="w-full h-auto text-slate-500 font-mono text-[8px]">
        <defs>
          <linearGradient id="sharedChartGrad" x1="0" y1="0" x2="0" y2="1">
            <stop offset="0%" stopColor="#10b981" stopOpacity="0.2" />
            <stop offset="100%" stopColor="#10b981" stopOpacity="0.0" />
          </linearGradient>
        </defs>
        
        {/* Grid Lines & Y labels */}
        {gridLines.map((line, idx) => {
          const label = line.value >= 1000000 
            ? `${(line.value / 1000000).toFixed(1)}M` 
            : line.value >= 1000 
              ? `${(line.value / 1000).toFixed(0)}k` 
              : `${Math.round(line.value)}`;
          return (
            <g key={idx}>
              <text x="5" y={line.y + 3} fill="currentColor" opacity="0.4">
                {label}
              </text>
              <line 
                x1="50" 
                y1={line.y} 
                x2="480" 
                y2={line.y} 
                stroke="currentColor" 
                strokeOpacity="0.08" 
                strokeDasharray="4 4" 
              />
            </g>
          );
        })}
        
        {/* Gradient Area Fill */}
        {fillPath && (
          <path d={fillPath} fill="url(#sharedChartGrad)" />
        )}
        
        {/* Stroke Line */}
        {linePath && (
          <path 
            d={linePath} 
            fill="none" 
            stroke="#10b981" 
            strokeWidth="2" 
            strokeLinecap="round" 
            strokeLinejoin="round" 
          />
        )}
        
        {/* Data Point Circles */}
        {points.map((pt, idx) => (
          <g key={idx}>
            <circle 
              cx={pt.x} 
              cy={pt.y} 
              r="3" 
              fill="#10b981" 
              stroke="#0f172a" 
              strokeWidth="1.5" 
            />
            <title>{`Ngày ${dailyData[idx].dateLabel}: ${dailyData[idx].value.toLocaleString('vi-VN')} đ`}</title>
          </g>
        ))}
        
        {/* X Axis Labels */}
        {dailyData.map((d, idx) => {
          const x = 50 + (idx / 6) * 430;
          return (
            <text 
              key={idx} 
              x={x} 
              y={height - 10} 
              textAnchor="middle" 
              fill="currentColor" 
              opacity="0.6"
            >
              {d.dateLabel}
            </text>
          );
        })}
      </svg>
    </div>
  );
}
