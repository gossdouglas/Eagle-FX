//+------------------------------------------------------------------+
//|                                               Duto_EntryExit.mqh |
//|                                               Tony Goss, 19Apr24 |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link "https://www.mql5.com"
#property strict


enum ENUM_SIGNAL_ENTRY
{
   SIGNAL_ENTRY_NEUTRAL = 0, // SIGNAL ENTRY NEUTRAL
   SIGNAL_ENTRY_BUY = 1,     // SIGNAL ENTRY BUY
   SIGNAL_ENTRY_SELL = -1,   // SIGNAL ENTRY SELL
};

enum ENUM_SIGNAL_EXIT{
   SIGNAL_EXIT_NEUTRAL=0,     //SIGNAL EXIT NEUTRAL
   SIGNAL_EXIT_BUY=1,         //SIGNAL EXIT BUY
   SIGNAL_EXIT_SELL=-1,        //SIGNAL EXIT SELL
   SIGNAL_EXIT_ALL=2,         //SIGNAL EXIT ALL
};

ENUM_SIGNAL_ENTRY SignalEntry = SIGNAL_ENTRY_NEUTRAL; // Entry signal variable
ENUM_SIGNAL_EXIT SignalExit=SIGNAL_EXIT_NEUTRAL;         //Exit signal variable

//-INPUT PARAMETERS-//
// The input parameters are the ones that can be set by the user when launching the EA
// If you place a comment following the input variable this will be shown as description of the field

//********************************************************************************************************

// THIS IS WHERE YOU SHOULD INCLUDE THE INPUT PARAMETERS FOR YOUR ENTRY AND EXIT SIGNALS

input string Comment_strategy = "=========="; // Risk Management Settings

// used in EvaluateEntry(), EvaluateExit()

input int MAFastPeriod = 10;                             // Fast MA Period, found settings
//input int MAFastPeriod = 15;                               // Fast MA Period, duto settings

input int MAFastShift = 0;                                 // Fast MA Shift

input ENUM_MA_METHOD MAFastMethod = MODE_SMA;              // Fast MA Method, found settings
//input ENUM_MA_METHOD MAFastMethod = MODE_SMMA;              // Fast MA Method, duto settings

//input ENUM_APPLIED_PRICE MAFastAppliedPrice = PRICE_WEIGHTED; // Fast MA Applied Price, duto settings
input ENUM_APPLIED_PRICE MAFastAppliedPrice = PRICE_CLOSE; // Fast MA Applied Price, found settings

input int MASlowPeriod = 25;                               // Slow MA Period
input int MASlowShift = 0;                                 // Slow MA Shift

input ENUM_MA_METHOD MASlowMethod = MODE_SMA;              // Slow MA Method, found settings
//input ENUM_MA_METHOD MASlowMethod = MODE_SMMA;              // Slow MA Method, duto settings

//input ENUM_APPLIED_PRICE MASlowAppliedPrice = PRICE_MEDIAN; // Slow MA Applied Price, duto settings
input ENUM_APPLIED_PRICE MASlowAppliedPrice = PRICE_CLOSE; // Slow MA Applied Price, found settings

// used in ExecuteTrailingStop(), StopLossPriceCalculate()
//input double PSARStopStep = 0.04; // Stop Loss PSAR Step
//input double PSARStopMax = 0.4;   // Stop Loss PSAR Max

// THIS IS WHERE YOU SHOULD INCLUDE THE INPUT PARAMETERS FOR YOUR ENTRY AND EXIT SIGNALS

//********************************************************************************************************

//for early testing to make sure the include file can be reached
void PrintTestToMACrossoverInclude()
{
   Print("Printed from the include file yo.");
}


ENUM_SIGNAL_ENTRY ReturnSignalEntryToEvaluateEntry()
{
   //indicator testing
   string indicatorName = "_Custom\\Duto\\macd_color_indicator_plot1_v0.8";
   string duto_chart_indicators = "_Custom\\Duto\\duto_chart_indicators_v0.5";
   string duto_chart_moving_averages = "_Custom\\Duto\\duto_mas";
   string duto_chart_deltas = "_Custom\\Duto\\delta_v0.1";

   //yellow line value
   double macd_color_indicator_pl1 = iCustom(Symbol(),Period(), indicatorName, 12, 26, 9, 4, 1);

   //duto chart indicators
   //double duto_chart_indicators_value = iCustom(Symbol(),Period(), duto_chart_indicators, 15, 25, 20, 30, 0, 1);
   //double duto_chart_indicators_value = iCustom(Symbol(),Period(), duto_chart_indicators, 15, 25, 20, 30, 0, 1);
   //double duto_chart_indicators_value = iCustom(Symbol(),Period(), duto_chart_indicators, 15, 25, 20, 30, 60, 13, 0, 100, 0, 1);

   double DeltaCollapsedPosBuffer_curr = iCustom(Symbol(),Period(), duto_chart_indicators, 5, 1);
   double DeltaCollapsedPosBuffer_prev = iCustom(Symbol(),Period(), duto_chart_indicators, 5, 2);

   

   //double duto_chart_moving_averages_value = iCustom(Symbol(),Period(), duto_chart_moving_averages, 15, 25, 0, 1);
   //double duto_chart_deltas_value = iCustom(Symbol(),Period(), duto_chart_deltas, 60, 13, 0, 100, 0, 1);
   
   // Declaring the variables for the entry and exit check
   SignalExit=SIGNAL_EXIT_NEUTRAL;

   /*

   double MASlowPrev = iMA(Symbol(), PERIOD_CURRENT, MASlowPeriod, MASlowShift, MASlowMethod, MASlowAppliedPrice, 1);
   double MASlowCurr = iMA(Symbol(), PERIOD_CURRENT, MASlowPeriod, MASlowShift, MASlowMethod, MASlowAppliedPrice, 0);
   double MAFastPrev = iMA(Symbol(), PERIOD_CURRENT, MAFastPeriod, MAFastShift, MAFastMethod, MAFastAppliedPrice, 1);
   double MAFastCurr = iMA(Symbol(), PERIOD_CURRENT, MAFastPeriod, MAFastShift, MAFastMethod, MAFastAppliedPrice, 0);

   // This is where you should insert your Entry Signal for BUY orders
   // Include a condition to open a buy order, the condition will have to set SignalEntry=SIGNAL_ENTRY_BUY
   if (MAFastPrev < MASlowPrev && MAFastCurr > MASlowCurr)
   {
      Print("macd_color_indicator_pl1 one candle back, value 5 ENTRY, buy: " + NormalizeDouble(macd_color_indicator_pl1, 6));

      SignalEntry = SIGNAL_ENTRY_BUY;     
   }

   // This is where you should insert your Entry Signal for SELL orders
   // Include a condition to open a sell order, the condition will have to set SignalEntry=SIGNAL_ENTRY_SELL
   if (MAFastPrev > MASlowPrev && MAFastCurr < MASlowCurr)
   {
      Print("macd_color_indicator_pl1 one candle back, value 5 ENTRY, sell: " + NormalizeDouble(macd_color_indicator_pl1, 6));

      SignalEntry = SIGNAL_ENTRY_SELL;
   }

   */

  if (DeltaCollapsedPosBuffer_curr != 2147483647 && DeltaCollapsedPosBuffer_prev == 2147483647) {
      //Print("A change from red to green has occured.");
      SignalEntry = SIGNAL_ENTRY_BUY;

   }
      
   //Print("return signal entry from ReturnSignalEntryToEvaluateEntry() in the include file.");
   //Print("macd_color_indicator_pl1 ENTRY: " + macd_color_indicator_pl1);

   return SignalEntry;
}

ENUM_SIGNAL_ENTRY ReturnSignalExitToEvaluateEntry()

{
   //indicator testing
   string indicatorName = "_Custom\\Duto\\macd_color_indicator_plot1_v0.8";
   string duto_chart_indicators = "_Custom\\Duto\\duto_chart_indicators_v0.5";
   string duto_chart_moving_averages = "_Custom\\Duto\\duto_mas";
   string duto_chart_deltas = "_Custom\\Duto\\delta_v0.1";

   //yellow line value
   double macd_color_indicator_pl1 = iCustom(Symbol(),Period(), indicatorName, 12, 26, 9, 4, 1);

   //duto chart indicators
   //double duto_chart_indicators_value = iCustom(Symbol(),Period(), duto_chart_indicators, 15, 25, 20, 30, 0, 1);
   //double duto_chart_indicators_value = iCustom(Symbol(),Period(), duto_chart_indicators, 15, 25, 20, 30, 0, 1);
   //double duto_chart_indicators_value = iCustom(Symbol(),Period(), duto_chart_indicators, 15, 25, 20, 30, 60, 13, 0, 100, 0, 1);

   double DeltaCollapsedPosBuffer_curr = iCustom(Symbol(),Period(), duto_chart_indicators, 5, 1);
   //Print("DeltaCollapsedPosBuffer_curr value to 5 is: " + NormalizeDouble(DeltaCollapsedPosBuffer_curr, 5));

   double DeltaCollapsedPosBuffer_prev = iCustom(Symbol(),Period(), duto_chart_indicators, 5, 2);
   //Print("DeltaCollapsedPosBuffer_prev value to 5 is: " + NormalizeDouble(DeltaCollapsedPosBuffer_prev, 5));

   //double duto_chart_moving_averages_value = iCustom(Symbol(),Period(), duto_chart_moving_averages, 15, 25, 0, 1);
   //double duto_chart_deltas_value = iCustom(Symbol(),Period(), duto_chart_deltas, 60, 13, 0, 100, 0, 1);
   
   // Declaring the variables for the entry and exit check
   SignalExit=SIGNAL_EXIT_NEUTRAL;

   /*

   double MASlowPrev=iMA(Symbol(),PERIOD_CURRENT,MASlowPeriod,MASlowShift,MASlowMethod,MASlowAppliedPrice,1);
   double MASlowCurr=iMA(Symbol(),PERIOD_CURRENT,MASlowPeriod,MASlowShift,MASlowMethod,MASlowAppliedPrice,0);
   double MAFastPrev=iMA(Symbol(),PERIOD_CURRENT,MAFastPeriod,MAFastShift,MAFastMethod,MAFastAppliedPrice,1);
   double MAFastCurr=iMA(Symbol(),PERIOD_CURRENT,MAFastPeriod,MAFastShift,MAFastMethod,MAFastAppliedPrice,0);

   //This is where you should include your exit signal for BUY orders
   //If you want, include a condition to close the open buy orders, condition will have to set SignalExit=SIGNAL_EXIT_BUY then return 
   if(MAFastPrev>MASlowPrev && MAFastCurr<MASlowCurr)
   {
      Print("macd_color_indicator_pl1 one candle back, value 5 EXIT, buy: " + NormalizeDouble(macd_color_indicator_pl1, 6));
      SignalExit=SIGNAL_EXIT_BUY;
   }
    
   //This is where you should include your exit signal for SELL orders
   //If you want, include a condition to close the open sell orders, condition will have to set SignalExit=SIGNAL_EXIT_SELL then return 
   if(MAFastPrev<MASlowPrev && MAFastCurr>MASlowCurr)
   {
      Print("macd_color_indicator_pl1 one candle back, value 5 EXIT, sell: " + NormalizeDouble(macd_color_indicator_pl1, 6));
      SignalExit=SIGNAL_EXIT_SELL;
   } 

   */

   return SignalEntry;
}




