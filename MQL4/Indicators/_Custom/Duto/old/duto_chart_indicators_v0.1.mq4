//+------------------------------------------------------------------+
//|                                        duto_chart_indicators.mq4 |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
#property indicator_chart_window

//moving average indicators
//--- plot FastMA
#property indicator_label1  "FastMA"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrYellow
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1
//--- plot SlowMA
#property indicator_label2  "SlowMA"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrRed
#property indicator_style2  STYLE_SOLID
#property indicator_width2  1
//--- input parameters
input int      FastMA=15;
input int      SlowMA=25;
//--- indicator buffers
double         FastMABuffer[];
double         SlowMABuffer[];


//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
SetIndexStyle(0, DRAW_LINE, EMPTY, 1, indicator_color1);
   SetIndexBuffer(0,FastMABuffer);
   SetIndexStyle(1, DRAW_LINE, EMPTY, 1, indicator_color2);
   SetIndexBuffer(1,SlowMABuffer);
   
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
//---

int limit;
   int counted_bars = IndicatorCounted();
   // Print("start() counted_bars: " + counted_bars);

   if (counted_bars < 0)
      return (-1);

   if (counted_bars > 0)
      counted_bars--;
   // Print("counted_bars2: " + counted_bars);
   // Print("Bars: " + Bars);

   limit = Bars - counted_bars;
   // Print("plot 1 indicator Bars from indicator start(): " + Bars);
   // Print("plot 1 indicator counted_bars from indicator start(): " + counted_bars);
   // Print("plot 1 indicator limit from indicator start(): " + limit);
   
   for (int i = 0; i < limit; i++)
   {
      // indicator_color6
      FastMABuffer[i] = iMA(NULL, 0, FastMA, 0, MODE_SMMA, PRICE_WEIGHTED, i);
      SlowMABuffer[i] = iMA(NULL, 0, SlowMA, 0, MODE_SMMA, PRICE_MEDIAN, i);
      // Print("ind_buffer4[" + i + "]: " + ind_buffer4[i]);

      if (i == 1)
      {

         // Print("ind_buffer4[" + i + "]: " + ind_buffer4[i]);
         // Print("----END");
      }
   }
   
//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
