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

bool IsNewCandle_Include=false;                   //Indicates if this is a new candle formed

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

//chart indicator history arrays
double FastMAHistoryBuffer[], SlowMAHistoryBuffer[], FiveFiftyMAHistoryBuffer[], DeltaCollapsedPosHistoryBuffer[], DeltaCollapsedNegHistoryBuffer[];
//MACD indicator history arrays
double MacdHistoryBuffer[],  MacdPlot2HistoryBuffer[], MacdPlot3HistoryBuffer[], MacdPlot4HistoryBuffer[];
//history array. a two dimensional array that stored indicator data from all time frames
//each time frame has 10 measurements
double CombinedHistory[1][40];

void LogIndicatorData()
{
   //indicator testing
   string indicatorName = "_Custom\\Duto\\macd_color_indicator_plot1_v0.9";
   string duto_chart_indicators = "_Custom\\Duto\\duto_chart_indicators_v0.5";
   string duto_chart_moving_averages = "_Custom\\Duto\\duto_mas";
   string duto_chart_deltas = "_Custom\\Duto\\delta_v0.1";
   string duto_sniper = "_Custom\\Duto\\SchaffTrendCycle";
   string strWriteLine, strWriteLine2 = "";
   int fileHandleIndicatorData;
   int periodArray[] = {60, 15, 5};
   
   //if the file exists, then delete it so only the most recent data is included
   if (FileIsExist("duto_indicator_data.csv")) {

      FileDelete("duto_indicator_data.csv");
   } 

   FileCopy("duto_indicator_data_blank.csv", 0, "duto_indicator_data.csv", 0);

   //open the file
   fileHandleIndicatorData = FileOpen("duto_indicator_data.csv", FILE_BIN | FILE_READ | FILE_WRITE | FILE_CSV);

   if (fileHandleIndicatorData < 1)
   {
      Print("can't open file error-", GetLastError());
      //return (0);
   }

   FileSeek(fileHandleIndicatorData, 0, SEEK_END);

   ArrayResize(FastMAHistoryBuffer, Bars + 1);
   ArrayResize(SlowMAHistoryBuffer, Bars + 1);
   ArrayResize(FiveFiftyMAHistoryBuffer, Bars + 1);
   ArrayResize(DeltaCollapsedPosHistoryBuffer, Bars + 1);
   ArrayResize(DeltaCollapsedNegHistoryBuffer, Bars + 1);

   ArrayResize(MacdHistoryBuffer, Bars + 1);
   ArrayResize(MacdPlot2HistoryBuffer, Bars + 1);
   ArrayResize(MacdPlot3HistoryBuffer, Bars + 1);
   ArrayResize(MacdPlot4HistoryBuffer, Bars + 1);

   ArrayResize(CombinedHistory, Bars + 1);

   for (int i = 0; i <= Bars; i++)
      {
         //build a line of data
         //60
         FastMAHistoryBuffer[i] = iCustom(Symbol(),60, duto_chart_indicators, 0, i);
         CombinedHistory[i][0] = i;//candle index
         CombinedHistory[i][2] = NormalizeDouble(FastMAHistoryBuffer[i], 5);//fast moving average
         
         SlowMAHistoryBuffer[i] = iCustom(Symbol(),60, duto_chart_indicators, 1, i);
         CombinedHistory[i][3] = SlowMAHistoryBuffer[i];//slow moving average

         FiveFiftyMAHistoryBuffer[i] = iCustom(Symbol(),60, duto_chart_indicators, 4, i);
         CombinedHistory[i][4] = FiveFiftyMAHistoryBuffer[i];//550 moving average

         DeltaCollapsedPosHistoryBuffer[i] = iCustom(Symbol(),60, duto_chart_indicators, 5, i);
         DeltaCollapsedNegHistoryBuffer[i] = iCustom(Symbol(),60, duto_chart_indicators, 6, i);

         if (DeltaCollapsedPosHistoryBuffer[i] == 2147483647) {
            CombinedHistory[i][5] = -1;//delta collapsed negative
         }
         else {
            CombinedHistory[i][5] = 1;//delta collapsed positive
         }

         MacdHistoryBuffer[i] = iCustom(Symbol(),60, indicatorName, 0, i);
         CombinedHistory[i][6] = MacdHistoryBuffer[i];//macd histogram

         MacdPlot2HistoryBuffer[i] = iCustom(Symbol(),60, indicatorName, 1, i);
         CombinedHistory[i][7] = MacdPlot2HistoryBuffer[i];//plot 2

         MacdPlot3HistoryBuffer[i] = iCustom(Symbol(),60, indicatorName, 2, i);
         CombinedHistory[i][8] = MacdPlot3HistoryBuffer[i];//plot 3

         MacdPlot4HistoryBuffer[i] = iCustom(Symbol(),60, indicatorName, 3, i);
         CombinedHistory[i][9] = MacdPlot4HistoryBuffer[i];//plot 4
      
         if (DeltaCollapsedPosHistoryBuffer[i] == 2147483647) {

            strWriteLine2 = ",Negative";
         }
         else {
            strWriteLine2 = ",Positive";
         }

         //build a line of strings based on a line of data
         strWriteLine = 
         i
         + "," + iTime(Symbol(), 60, i) 

         + "," + DoubleToString(FastMAHistoryBuffer[i], 5)
         + "," + DoubleToString(SlowMAHistoryBuffer[i], 5)
         + "," + DoubleToString(FiveFiftyMAHistoryBuffer[i], 5)

         + strWriteLine2
         
         + "," + DoubleToString(MacdHistoryBuffer[i], 7)
         + "," + DoubleToString(MacdPlot2HistoryBuffer[i], 7)
         + "," + DoubleToString(MacdPlot3HistoryBuffer[i], 7)
         + "," + DoubleToString(MacdPlot4HistoryBuffer[i], 7)
         + "";

         //build a line of data
         //15
         FastMAHistoryBuffer[i] = iCustom(Symbol(),15, duto_chart_indicators, 0, i);
         CombinedHistory[i][10] = i;//candle index
         CombinedHistory[i][12] = FastMAHistoryBuffer[i];//fast moving average
         
         SlowMAHistoryBuffer[i] = iCustom(Symbol(),15, duto_chart_indicators, 1, i);
         CombinedHistory[i][13] = SlowMAHistoryBuffer[i];//slow moving average

         FiveFiftyMAHistoryBuffer[i] = iCustom(Symbol(),15, duto_chart_indicators, 4, i);
         CombinedHistory[i][14] = FiveFiftyMAHistoryBuffer[i];//550 moving average

         DeltaCollapsedPosHistoryBuffer[i] = iCustom(Symbol(),15, duto_chart_indicators, 5, i);
         DeltaCollapsedNegHistoryBuffer[i] = iCustom(Symbol(),15, duto_chart_indicators, 6, i);

         if (DeltaCollapsedPosHistoryBuffer[i] == 2147483647) {
            CombinedHistory[i][15] = -1;//delta collapsed negative
         }
         else {
            CombinedHistory[i][15] = 1;//delta collapsed positive
         }

         MacdHistoryBuffer[i] = iCustom(Symbol(),15, indicatorName, 0, i);
         CombinedHistory[i][16] = MacdHistoryBuffer[i];//macd histogram

         MacdPlot2HistoryBuffer[i] = iCustom(Symbol(),15, indicatorName, 1, i);
         CombinedHistory[i][17] = MacdPlot2HistoryBuffer[i];//plot 2

         MacdPlot3HistoryBuffer[i] = iCustom(Symbol(),15, indicatorName, 2, i);
         CombinedHistory[i][18] = MacdPlot3HistoryBuffer[i];//plot 3

         MacdPlot4HistoryBuffer[i] = iCustom(Symbol(),15, indicatorName, 3, i);
         CombinedHistory[i][19] = MacdPlot4HistoryBuffer[i];//plot 4

         if (DeltaCollapsedPosHistoryBuffer[i] == 2147483647) {

            strWriteLine2 = ",Negative";
         }
         else {
            strWriteLine2 = ",Positive";
         }

         //build a line of strings based on a line of data
         strWriteLine = strWriteLine +
         //",Candle " + i
         "," + i
         + "," + iTime(Symbol(), 15, i) 

         + "," + DoubleToString(FastMAHistoryBuffer[i], 5)
         + "," + DoubleToString(SlowMAHistoryBuffer[i], 5)
         + "," + DoubleToString(FiveFiftyMAHistoryBuffer[i], 5)

         + strWriteLine2
         
         + "," + DoubleToString(MacdHistoryBuffer[i], 7)
         + "," + DoubleToString(MacdPlot2HistoryBuffer[i], 7)
         + "," + DoubleToString(MacdPlot3HistoryBuffer[i], 7)
         + "," + DoubleToString(MacdPlot4HistoryBuffer[i], 7)
         + "";

         //build a line of data
         //5
         FastMAHistoryBuffer[i] = iCustom(Symbol(),5, duto_chart_indicators, 0, i);
         CombinedHistory[i][20] = i;//candle index
         CombinedHistory[i][22] = FastMAHistoryBuffer[i];//fast moving average
         
         SlowMAHistoryBuffer[i] = iCustom(Symbol(),5, duto_chart_indicators, 1, i);
         CombinedHistory[i][23] = SlowMAHistoryBuffer[i];//slow moving average

         FiveFiftyMAHistoryBuffer[i] = iCustom(Symbol(),5, duto_chart_indicators, 4, i);
         CombinedHistory[i][24] = FiveFiftyMAHistoryBuffer[i];//550 moving average

         DeltaCollapsedPosHistoryBuffer[i] = iCustom(Symbol(),5, duto_chart_indicators, 5, i);
         DeltaCollapsedNegHistoryBuffer[i] = iCustom(Symbol(),5, duto_chart_indicators, 6, i);

         if (DeltaCollapsedPosHistoryBuffer[i] == 2147483647) {
            CombinedHistory[i][25] = -1;//delta collapsed negative
         }
         else {
            CombinedHistory[i][25] = 1;//delta collapsed positive
         }

         MacdHistoryBuffer[i] = iCustom(Symbol(),5, indicatorName, 0, i);
         CombinedHistory[i][26] = MacdHistoryBuffer[i];//macd histogram

         MacdPlot2HistoryBuffer[i] = iCustom(Symbol(),5, indicatorName, 1, i);
         CombinedHistory[i][27] = MacdPlot2HistoryBuffer[i];//plot 2

         MacdPlot3HistoryBuffer[i] = iCustom(Symbol(),5, indicatorName, 2, i);
         CombinedHistory[i][28] = MacdPlot3HistoryBuffer[i];//plot 3

         MacdPlot4HistoryBuffer[i] = iCustom(Symbol(),5, indicatorName, 3, i);
         CombinedHistory[i][29] = MacdPlot4HistoryBuffer[i];//plot 4

         if (DeltaCollapsedPosHistoryBuffer[i] == 2147483647) {

            strWriteLine2 = ",Negative";
         }
         else {
            strWriteLine2 = ",Positive";
         }

         //build a line of strings based on a line of data
         strWriteLine = strWriteLine +
         "," + i
         + "," + iTime(Symbol(), 5, i) 

         + "," + DoubleToString(FastMAHistoryBuffer[i], 5)
         + "," + DoubleToString(SlowMAHistoryBuffer[i], 5)
         + "," + DoubleToString(FiveFiftyMAHistoryBuffer[i], 5)

         + strWriteLine2
         
         + "," + DoubleToString(MacdHistoryBuffer[i], 7)
         + "," + DoubleToString(MacdPlot2HistoryBuffer[i], 7)
         + "," + DoubleToString(MacdPlot3HistoryBuffer[i], 7)
         + "," + DoubleToString(MacdPlot4HistoryBuffer[i], 7)
         + "";

         //build a line of data
         //1
         FastMAHistoryBuffer[i] = iCustom(Symbol(),1, duto_chart_indicators, 0, i);
         CombinedHistory[i][30] = i;//candle index
         CombinedHistory[i][32] = FastMAHistoryBuffer[i];//fast moving average
         
         SlowMAHistoryBuffer[i] = iCustom(Symbol(),1, duto_chart_indicators, 1, i);
         CombinedHistory[i][33] = SlowMAHistoryBuffer[i];//slow moving average

         FiveFiftyMAHistoryBuffer[i] = iCustom(Symbol(),1, duto_chart_indicators, 4, i);
         CombinedHistory[i][34] = FiveFiftyMAHistoryBuffer[i];//550 moving average

         DeltaCollapsedPosHistoryBuffer[i] = iCustom(Symbol(),1, duto_chart_indicators, 5, i);
         DeltaCollapsedNegHistoryBuffer[i] = iCustom(Symbol(),1, duto_chart_indicators, 6, i);

         if (DeltaCollapsedPosHistoryBuffer[i] == 2147483647) {
            CombinedHistory[i][35] = -1;//delta collapsed negative
         }
         else {
            CombinedHistory[i][35] = 1;//delta collapsed positive
         }

         MacdHistoryBuffer[i] = iCustom(Symbol(),1, indicatorName, 0, i);
         CombinedHistory[i][36] = MacdHistoryBuffer[i];//macd histogram

         MacdPlot2HistoryBuffer[i] = iCustom(Symbol(),1, indicatorName, 1, i);
         CombinedHistory[i][37] = MacdPlot2HistoryBuffer[i];//plot 2

         MacdPlot3HistoryBuffer[i] = iCustom(Symbol(),1, indicatorName, 2, i);
         CombinedHistory[i][38] = MacdPlot3HistoryBuffer[i];//plot 3

         MacdPlot4HistoryBuffer[i] = iCustom(Symbol(),1, indicatorName, 3, i);
         CombinedHistory[i][39] = MacdPlot4HistoryBuffer[i];//plot 4

         //Print("MacdPlot4HistoryBuffer[i]: " + NormalizeDouble(MacdPlot4HistoryBuffer[i] ,6)  + " CombinedHistory[i][39]: " + NormalizeDouble(CombinedHistory[i][39] ,6));

         if (DeltaCollapsedPosHistoryBuffer[i] == 2147483647) {

            strWriteLine2 = ",Negative";
         }
         else {
            strWriteLine2 = ",Positive";
         }

         //build a line of strings based on a line of data
         strWriteLine = strWriteLine +
         "," + i
         + "," + iTime(Symbol(), 1, i) 

         + "," + DoubleToString(FastMAHistoryBuffer[i], 5)
         + "," + DoubleToString(SlowMAHistoryBuffer[i], 5)
         + "," + DoubleToString(FiveFiftyMAHistoryBuffer[i], 5)

         + strWriteLine2
         
         + "," + DoubleToString(MacdHistoryBuffer[i], 7)
         + "," + DoubleToString(MacdPlot2HistoryBuffer[i], 7)
         + "," + DoubleToString(MacdPlot3HistoryBuffer[i], 7)
         + "," + DoubleToString(MacdPlot4HistoryBuffer[i], 7)

         + "\r\n";

         //write a line of strings to a file
         FileWriteString(fileHandleIndicatorData, strWriteLine, StringLen(strWriteLine));

         /* //check combined history data with output
         Print("check combined history data with output");
         string combinedHistoryOutput = "";

         for (int col = 0; col <= 39; col++)
         {
            combinedHistoryOutput = combinedHistoryOutput + CombinedHistory[i][col] + ", ";
            //Print(CombinedHistory[i][col] + ", ");
         }

         Print(combinedHistoryOutput); */
      }  

   FileClose(fileHandleIndicatorData); 
}

ENUM_SIGNAL_ENTRY ReturnSignalEntryToEvaluateEntry()
{  
   // Declaring the variables for the entry and exit check
   SignalEntry = SIGNAL_ENTRY_NEUTRAL;

   //strategy to be used for entry
   //SignalEntry = DutoSun3_2Entry();
   SignalEntry = DutoSunOverhaul_Entry();

   return SignalEntry;
}

ENUM_SIGNAL_EXIT ReturnSignalExitToEvaluateExit()

{
   // Declaring the variables for the entry and exit check
   SignalExit = SIGNAL_EXIT_NEUTRAL;

   //strategy to be used for exit
   //SignalExit = DutoSun3_2Exit();
   SignalExit = DutoSunOverhaul_Exit();

   return SignalExit;
}

//Check if it is a new bar
datetime NewBarTime_Include=TimeCurrent();
void CheckNewBar_Include(){
   //NewBarTime contains the open time of the last bar known
   //if that open time is the same as the current bar then we are still in the current bar, otherwise we are in a new bar
   if(NewBarTime_Include==Time[0]) IsNewCandle_Include=false;
   else{
      NewBarTime_Include=Time[0];
      IsNewCandle_Include=true;
   }
}

//
double FastMAIndicatorHistory[100];
double SlowMAIndicatorHistory[100];
double DeltaCIndicatorHistory[100];
double FiveFiftyIndicatorHistory[100];

double MacdIndicatorHistory[100];
double Plot2IndicatorHistory[100];
double Plot3IndicatorHistory[100];
double Plot4IndicatorHistory[100];

void GetIndicatorHistory(int indicatorIndex, int numCandles)
{
   //resize the arrays to match the passed number of candles of interest
   ArrayResize(FastMAIndicatorHistory, numCandles);
   ArrayResize(SlowMAIndicatorHistory, numCandles);
   ArrayResize(DeltaCIndicatorHistory, numCandles);
   ArrayResize(FiveFiftyIndicatorHistory, numCandles);

   ArrayResize(MacdIndicatorHistory, numCandles);
   ArrayResize(Plot2IndicatorHistory, numCandles);
   ArrayResize(Plot3IndicatorHistory, numCandles);
   ArrayResize(Plot4IndicatorHistory, numCandles);

   //Print("Resize DeltaCIndicatorHistory to " + (numCandles));

   for (int candleNumber = 0; candleNumber <= numCandles - 1; candleNumber++)
   {
      FastMAIndicatorHistory[candleNumber] = CombinedHistory[candleNumber][indicatorIndex];
      SlowMAIndicatorHistory[candleNumber] = CombinedHistory[candleNumber][indicatorIndex + 1];
      DeltaCIndicatorHistory[candleNumber] = CombinedHistory[candleNumber][indicatorIndex] + 2;
      FiveFiftyIndicatorHistory[candleNumber] = CombinedHistory[candleNumber][indicatorIndex + 3];

      MacdIndicatorHistory[candleNumber] = CombinedHistory[candleNumber][indicatorIndex + 4];
      Plot2IndicatorHistory[candleNumber] = CombinedHistory[candleNumber][indicatorIndex + 5];
      Plot3IndicatorHistory[candleNumber] = CombinedHistory[candleNumber][indicatorIndex + 6];
      Plot4IndicatorHistory[candleNumber] = CombinedHistory[candleNumber][indicatorIndex + 7];

      //Print("DeltaCIndicatorHistory[" + candleNumber + "]: " + DeltaCIndicatorHistory[candleNumber]);
      //Print("DeltaCIndicatorHistory[" + candleNumber + "]: " + DeltaCIndicatorHistory[candleNumber]);
   }
}

//////STRATEGIES BEGIN

double EntryData[2][11];

//DutoSunOverhaul

/* OVERALL SELL STRATEGY

If the M5 plot 3 changes from bright green to dark green or dark green to bright red
then enter an overall sell strategy that is signalled by the Boolean variable SellStrategyActive being set to true. 
This overall strategy ends when the M5 plot 3 changes from dark green to bright green or from bright red to dark red.

-bright green to dark green indicates a decreasing positive trend.

-dark green to bright red indicates a switch to a negative trend from a decreasing positive trend.

TRADES WHEN THE  SELL STRATEGY IS ACTIVE

Sells will be entered and exited based upon conditions of the MACD  M1 chart.  A sell may be entered on the  
first available dark green candle or the first available bright red candle.  

Dark green entries will be exited when a bright green candle or dark red candle appears. 

Bright red entries will be exited when a dark red candle appears. 

Sell trades will be entered and exited again and again until conditions on the M5 plot 2 set the boolean variable SellStrategyActive to false.  */

bool SellStrategyActive, BuyStrategyActive, NeutralStrategyActive;
bool BuyNegativeStrategyActive, BuyPositiveStrategyActive;

bool BuyDkGrBrGrStrategyActive, SellBrGrDkGrStrategyActive;
bool SellDkGrBrRdStrategyActive, BuyBrRdDkRdStrategyActive;
bool SellDkRdBrRdStrategyActive;

bool SellTradeActive, BuyTradeActive;

ENUM_SIGNAL_ENTRY DutoSunOverhaul_Entry()
{
   //OVERALL STRATEGY LOGIC

   /* //NEUTRAL STRATEGY CHECK
   if (
      (AskThePlots(1, 1, 1, "NEUTRAL") == "PLOT STEADY NEUTRAL") 
      //&& (AskThePlots(28, 1, 1, "NEUTRAL") == "PLOT STEADY NEUTRAL") 
      //&& (AskThePlots(29, 1, 1, "NEUTRAL") == "PLOT STEADY NEUTRAL")
      && NeutralStrategyActive == false
      )     
   {
      SellStrategyActive = false;
      BuyStrategyActive = false;
      NeutralStrategyActive = true;

      Print("PLOT STEADY NEUTRAL. SellStrategyActive: " + SellStrategyActive + " BuyStrategyActive: " + BuyStrategyActive 
      + " NeutralStrategyActive: " + NeutralStrategyActive);
   } */
   
   //BUY STRATEGY CHECK FOR DARK GREEN TO BRIGHT GREEN
   if (
      (AskThePlots(28, 1, 1, "BUY_DK_GREEN_BR_GREEN") == "PLOT INCREASING DARK GREEN TO BRIGHT GREEN") 
      && BuyStrategyActive == false
      )
   {
      SellStrategyActive = false;
      BuyStrategyActive = true;
      NeutralStrategyActive = false;

      //BuyNegativeStrategyActive =  false;
      //BuyPositiveStrategyActive =  true;
      BuyDkGrBrGrStrategyActive = true;
      SellBrGrDkGrStrategyActive = false;
      SellDkGrBrRdStrategyActive = false;
      BuyBrRdDkRdStrategyActive = false;
      SellDkRdBrRdStrategyActive = false;

      Print("A BUY STRATEGY IN EFFECT. SellStrategyActive: " + SellStrategyActive + " BuyStrategyActive: " + BuyStrategyActive 
      + " NeutralStrategyActive: " + NeutralStrategyActive);
      Print("PLOT INCREASING DARK GREEN TO BRIGHT GREEN POSITIVE. BuyDkGrBrGrStrategyActive: " + BuyDkGrBrGrStrategyActive);
   }
   else
   //SELL STRATEGY CHECK FOR BRIGHT GREEN TO DARK GREEN
   if (
      (AskThePlots(28, 1, 1, "SELL_BR_GREEN_DK_GREEN") == "PLOT DECREASING BRIGHT GREEN TO DARK GREEN") 
      && SellStrategyActive == false
      )
   {
      SellStrategyActive = true;
      BuyStrategyActive = false;
      NeutralStrategyActive = false;

      //BuyNegativeStrategyActive =  false;
      //BuyPositiveStrategyActive =  true;
      BuyDkGrBrGrStrategyActive = false;
      SellBrGrDkGrStrategyActive = true;
      SellDkGrBrRdStrategyActive = false;
      BuyBrRdDkRdStrategyActive = false;
      SellDkRdBrRdStrategyActive = false;

      Print("A SELL STRATEGY IN EFFECT. SellStrategyActive: " + SellStrategyActive + " BuyStrategyActive: " + BuyStrategyActive 
      + " NeutralStrategyActive: " + NeutralStrategyActive);
      Print("PLOT DECREASING BRIGHT GREEN TO DARK GREEN POSITIVE. SellBrGrDkGrStrategyActive: " + SellBrGrDkGrStrategyActive);
   }
   else
   //SELL STRATEGY CHECK FOR DARK GREEN TO BRIGHT RED
   if (
      (AskThePlots(28, 1, 1, "SELL_DK_GREEN_BR_RED") == "PLOT DECREASING DARK GREEN TO BRIGHT RED") 
      //&& SellStrategyActive == false
      )
   {
      SellStrategyActive = true;
      BuyStrategyActive = false;
      NeutralStrategyActive = false;

      //BuyNegativeStrategyActive =  false;
      //BuyPositiveStrategyActive =  true;
      BuyDkGrBrGrStrategyActive = false;
      SellBrGrDkGrStrategyActive = false;
      SellDkGrBrRdStrategyActive = true;
      BuyBrRdDkRdStrategyActive = false;
      SellDkRdBrRdStrategyActive = false;

      Print("A SELL STRATEGY IN EFFECT. SellStrategyActive: " + SellStrategyActive + " BuyStrategyActive: " + BuyStrategyActive 
      + " NeutralStrategyActive: " + NeutralStrategyActive);
      Print("PLOT DECREASING DARK GREEN TO BRIGHT RED. SellDkGrBrRdStrategyActive: " + SellDkGrBrRdStrategyActive);
   }
   else
   //BUY STRATEGY CHECK FOR BRIGHT RED TO DARK RED
   if (
      (AskThePlots(28, 1, 1, "BUY_BR_RED_DK_RED") == "PLOT INCREASING BRIGHT RED TO DARK RED") 
      //&& SellStrategyActive == false
      )
   {
      SellStrategyActive = false;
      BuyStrategyActive = true;
      NeutralStrategyActive = false;

      //BuyNegativeStrategyActive =  false;
      //BuyPositiveStrategyActive =  true;
      BuyDkGrBrGrStrategyActive = false;
      SellBrGrDkGrStrategyActive = false;
      SellDkGrBrRdStrategyActive = false;
      BuyBrRdDkRdStrategyActive = true;
      SellDkRdBrRdStrategyActive = false;

      Print("A BUY STRATEGY IN EFFECT. SellStrategyActive: " + SellStrategyActive + " BuyStrategyActive: " + BuyStrategyActive 
      + " NeutralStrategyActive: " + NeutralStrategyActive);
      Print("PLOT INCEASING BRIGHT RED TO DARK RED. BuyBrRdDkRdStrategyActive: " + BuyBrRdDkRdStrategyActive);
   }
   else
   //SELL STRATEGY CHECK FOR DARK RED TO BRIGHT RED
   if (
      (AskThePlots(28, 1, 1, "SELL_DK_RED_BR_RED") == "PLOT DECREASING DARK RED TO BRIGHT RED") 
      //&& SellStrategyActive == false
      )
   {
      SellStrategyActive = true;
      BuyStrategyActive = false;
      NeutralStrategyActive = false;

      //BuyNegativeStrategyActive =  false;
      //BuyPositiveStrategyActive =  true;
      BuyDkGrBrGrStrategyActive = false;
      SellBrGrDkGrStrategyActive = false;
      SellDkGrBrRdStrategyActive = true;
      BuyBrRdDkRdStrategyActive = false;
      SellDkRdBrRdStrategyActive = true;

      Print("A SELL STRATEGY IN EFFECT. SellStrategyActive: " + SellStrategyActive + " BuyStrategyActive: " + BuyStrategyActive 
      + " NeutralStrategyActive: " + NeutralStrategyActive);
      Print("PLOT DECREASING DARK RED TO BRIGHT RED. SellDkRdBrRdStrategyActive: " + SellDkRdBrRdStrategyActive);
   }


   //ENTRY LOGIC

   //BUY ENTRY, DARK GREEN TO BRIGHT GREEN
   if (
         //MACD INCREASING FROM NEGATIVE TO POSITIVE
         //(AskThePlots(36, 1, 1, "BUY_DK_GREEN_BR_GREEN_ENTRY") == "ENTER A BUY DARK GREEN BRIGHT GREEN") 
         //PLOT 3 INCREASING POSITIVE
         (AskThePlots(38, 1, 1, "BUY_DK_GREEN_BR_GREEN_ENTRY") == "ENTER A BUY DARK GREEN BRIGHT GREEN") 

      && BuyStrategyActive == true 
      && BuyTradeActive == false

      && BuyDkGrBrGrStrategyActive == true
      )
   {
      BuyTradeActive = true;

      Print("ENTER A BUY, DARK GREEN TO BRIGHT GREEN. " +
      "BuyStrategyActive: " + BuyStrategyActive + 
      " BuyTradeActive: " + BuyTradeActive + 
      " BuyDkGrBrGrStrategyActive: " + BuyDkGrBrGrStrategyActive);
      SignalEntry = SIGNAL_ENTRY_BUY;
   }

   //SELL ENTRY, BRIGHT GREEN TO DARK GREEN
   if (
         (AskThePlots(38, 1, 1, "SELL_BR_GREEN_DK_GREEN_ENTRY") == "ENTER A SELL BRIGHT GREEN DARK GREEN") 
      && SellStrategyActive == true 
      && SellTradeActive == false

      && SellBrGrDkGrStrategyActive == true
      )
   {
      SellTradeActive = true;

      Print("ENTER A SELL, BRIGHT GREEN TO DARK GREEN. " +
      "SellStrategyActive: " + SellStrategyActive + 
      " BuyTradeActive: " + BuyTradeActive + 
      " SellBrGrDkGrStrategyActive: " + SellBrGrDkGrStrategyActive);
      SignalEntry = SIGNAL_ENTRY_SELL;
   }

   //SELL ENTRY, DARK GREEN TO BRIGHT RED
   if (
         (AskThePlots(38, 1, 1, "SELL_DK_GREEN_BR_RED_ENTRY") == "ENTER A SELL DARK GREEN BRIGHT RED") 
      && SellStrategyActive == true 
      && SellTradeActive == false

      && SellDkGrBrRdStrategyActive == true
      )
   {
      SellTradeActive = true;

      Print("ENTER A SELL, DARK GREEN TO BRIGHT RED. " +
      "SellStrategyActive: " + SellStrategyActive + 
      " BuyTradeActive: " + BuyTradeActive + 
      " SellDkGrBrRdStrategyActive: " + SellDkGrBrRdStrategyActive);
      SignalEntry = SIGNAL_ENTRY_SELL;
   }

   //BUY ENTRY, BRIGHT RED TO DARK RED
   if (
         (AskThePlots(38, 1, 1, "BUY_BR_RED_DK_RED_ENTRY") == "ENTER A BUY BRIGHT RED DARK RED") 
      && BuyStrategyActive == true 
      && BuyTradeActive == false

      && BuyBrRdDkRdStrategyActive == true
      )
   {
      BuyTradeActive = true;

      Print("ENTER A BUY, BRIGHT RED TO DARK RED. " +
      "SellTradeActive: " + SellTradeActive + 
      " BuyTradeActive: " + BuyTradeActive + 
      " BuyBrRdDkRdStrategyActive: " + BuyBrRdDkRdStrategyActive);
      SignalEntry = SIGNAL_ENTRY_BUY;
   }

   //SELL ENTRY, DARK RED TO BRIGHT RED
   if (
         (AskThePlots(38, 1, 1, "SELL_DK_RED_BR_RED_ENTRY") == "ENTER A SELL DARK RED BRIGHT RED") 
      && SellStrategyActive == true 
      && SellTradeActive == false

      && SellDkRdBrRdStrategyActive == true
      )
   {
      SellTradeActive = true;

      Print("ENTER A SELL, DARK RED TO BRIGHT RED. " +
      "SellStrategyActive: " + SellStrategyActive + 
      " BuyTradeActive: " + BuyTradeActive + 
      " SellDkRdBrRdStrategyActive: " + SellDkRdBrRdStrategyActive);
      SignalEntry = SIGNAL_ENTRY_SELL;
   }

   //SignalEntry = SIGNAL_ENTRY_NEUTRAL;

   return SignalEntry;
}

ENUM_SIGNAL_EXIT DutoSunOverhaul_Exit()
{ 
   //EXIT LOGIC

   //BUY EXIT, DARK GREEN TO BRIGHT GREEN
   if (
      AskThePlots(36, 1, 1, "BUY_DK_GREEN_BR_GREEN_EXIT") == "EXIT A BUY DARK GREEN BRIGHT GREEN"
      && BuyStrategyActive == true 
      && BuyTradeActive == true

      && BuyDkGrBrGrStrategyActive == true
      )
   {
      BuyTradeActive = false;
      BuyDkGrBrGrStrategyActive = false;

      Print("EXIT A BUY, DARK GREEN TO BRIGHT GREEN. SellStrategyActive: " + SellStrategyActive + " BuyStrategyActive: " + BuyStrategyActive);
      SignalExit = SIGNAL_EXIT_BUY;
   }

   //SELL EXIT, BRIGHT GREEN TO DARK GREEN
   if (
      AskThePlots(36, 1, 1, "SELL_BR_GREEN_DK_GREEN_EXIT") == "EXIT A SELL BRIGHT GREEN DARK GREEN"
      && SellStrategyActive == true 
      && SellTradeActive == true

      && SellBrGrDkGrStrategyActive == true
      )
   {
      SellTradeActive = false;
      SellBrGrDkGrStrategyActive = false;

      Print("EXIT A SELL, BRIGHT GREEN TO DARK GREEN. SellStrategyActive: " + SellStrategyActive + " BuyStrategyActive: " + BuyStrategyActive);
      SignalExit = SIGNAL_EXIT_SELL;
   }

   //SELL EXIT, DARK GREEN TO BRIGHT RED
   if (
      AskThePlots(36, 1, 1, "SELL_DK_GREEN_BR_RED_EXIT") == "EXIT A SELL DARK GREEN BRIGHT RED"
      && SellStrategyActive == true 
      && SellTradeActive == true

      && SellDkGrBrRdStrategyActive == true
      )
   {
      SellTradeActive = false;
      SellDkGrBrRdStrategyActive = false;

      Print("EXIT A SELL, DARK GREEN TO BRIGHT RED. SellStrategyActive: " + SellStrategyActive + " BuyStrategyActive: " + BuyStrategyActive);
      SignalExit = SIGNAL_EXIT_SELL;
   }

   //BUY EXIT, BRIGHT RED TO DARK RED
   if (
      AskThePlots(36, 1, 1, "BUY_BR_RED_DK_RED_EXIT") == "EXIT A BUY BRIGHT RED DARK RED"
      && BuyStrategyActive == true 
      && BuyTradeActive == true

      && BuyBrRdDkRdStrategyActive == true
      )
   {
      BuyTradeActive = false;
      BuyBrRdDkRdStrategyActive = false;

      Print("EXIT A BUY, BRIGHT RED TO DARK RED. SellStrategyActive: " + SellStrategyActive + " BuyStrategyActive: " + BuyStrategyActive);
      SignalExit = SIGNAL_EXIT_BUY;
   }

   //SELL EXIT, DARK RED TO BRIGHT RED
   if (
      AskThePlots(36, 1, 1, "SELL_DK_RED_BR_RED_EXIT") == "EXIT A SELL DARK RED BRIGHT RED"
      && SellStrategyActive == true 
      && SellTradeActive == true

      && SellDkRdBrRdStrategyActive == true
      )
   {
      SellTradeActive = false;
      SellDkRdBrRdStrategyActive = false;

      Print("EXIT A SELL, DARK RED TO BRIGHT RED. SellStrategyActive: " + SellStrategyActive + " BuyStrategyActive: " + BuyStrategyActive);
      SignalExit = SIGNAL_EXIT_SELL;
   }

   return SignalExit;
}

//functions

/* //hump logic
      CombinedHistory[CndleStart][Idx] < CombinedHistory[CndleStart + 1][Idx]
      && CombinedHistory[CndleStart + 1][Idx] > CombinedHistory[CndleStart + 2][Idx]  */ 

string AskThePlots(int Idx, int CndleStart, int CmbndHstryCandleLength, string OverallStrategy)
{
   string result = "PLOT STEADY NEUTRAL";

   //STRATEGY LOGIC

   /* //NEUTRAL STRATEGY
   if (
      OverallStrategy == "NEUTRAL"
      &&

      //CONDITIONS NOT RIGHT FOR A BUY DARK GREEN TO BRIGHT GREEN STRATEGY
      !(
         //candle 1 greater than or equal to candle 2
         NormalizeDouble(CombinedHistory[CndleStart][Idx] ,7) >= NormalizeDouble(CombinedHistory[CndleStart + 1][Idx] ,7) 
         //candle 2 less than or equal to candle 3
         && NormalizeDouble(CombinedHistory[CndleStart + 1][Idx] ,7) <= NormalizeDouble(CombinedHistory[CndleStart + 2][Idx] ,7) 
         //candle 1 is positive
         && CombinedHistory[CndleStart][Idx] > 0
      )
      )
   {
      //Print("neutral " + Idx);
      result = "PLOT STEADY NEUTRAL";
   } */

   /* //SELL STRATEGY
   if (
      OverallStrategy == "SELL"
      && CombinedHistory[CndleStart][Idx] < CombinedHistory[CndleStart + 1][Idx]
      && CombinedHistory[CndleStart][Idx] < CombinedHistory[CndleStart + 2][Idx]

      //keep or not?
      && CombinedHistory[CndleStart][Idx] < 0   
      )
   {
      result = "PLOT INCREASING NEGATIVE";
   } */
 
   //BUY STRATEGY, DARK GREEN TO BRIGHT GREEN
   if (
      OverallStrategy == "BUY_DK_GREEN_BR_GREEN"

      //candle 1 greater than or equal to candle 2
      && NormalizeDouble(CombinedHistory[CndleStart][Idx] ,7) >= NormalizeDouble(CombinedHistory[CndleStart + 1][Idx] ,7) 
      //candle 2 less than or equal to candle 3
      && NormalizeDouble(CombinedHistory[CndleStart + 1][Idx] ,7) <= NormalizeDouble(CombinedHistory[CndleStart + 2][Idx] ,7) 
      //candle 1 is positive
      && CombinedHistory[CndleStart][Idx] > 0
      )
   {
      result = "PLOT INCREASING DARK GREEN TO BRIGHT GREEN";
   }
   else
   //SELL STRATEGY, BRIGHT GREEN TO DARK GREEN
   if (
      OverallStrategy == "SELL_BR_GREEN_DK_GREEN"

      //candle 1 less than or equal to candle 2
      && NormalizeDouble(CombinedHistory[CndleStart][Idx] ,7) <= NormalizeDouble(CombinedHistory[CndleStart + 1][Idx] ,7) 
      //candle 2 greater than or equal to candle 3
      && NormalizeDouble(CombinedHistory[CndleStart + 1][Idx] ,7) >= NormalizeDouble(CombinedHistory[CndleStart + 2][Idx] ,7) 
      //candle 1 is positive
      && CombinedHistory[CndleStart][Idx] > 0
      )
   {
      result = "PLOT DECREASING BRIGHT GREEN TO DARK GREEN";
   }
   else
   //SELL STRATEGY, DARK GREEN TO BRIGHT RED
   if (
      OverallStrategy == "SELL_DK_GREEN_BR_RED"

      //candle 1 less than or equal to candle 2
      && NormalizeDouble(CombinedHistory[CndleStart][Idx] ,7) <= NormalizeDouble(CombinedHistory[CndleStart + 1][Idx] ,7) 
      //candle 2 less than or equal to candle 3
      && NormalizeDouble(CombinedHistory[CndleStart + 1][Idx] ,7) <= NormalizeDouble(CombinedHistory[CndleStart + 2][Idx] ,7) 
      //candle 1 is negative, candle 2 is positive, candle 3 is positive
      && CombinedHistory[CndleStart][Idx] < 0 && CombinedHistory[CndleStart + 1][Idx] > 0 && CombinedHistory[CndleStart + 2][Idx] > 0
      )
   {
      //Print("TEST TEST PLOT DECREASING DARK GREEN TO BRIGHT RED");
      result = "PLOT DECREASING DARK GREEN TO BRIGHT RED";
   }
   //BUY STRATEGY, BRIGHT RED TO DARK RED
   if (
      OverallStrategy == "BUY_BR_RED_DK_RED"

      //candle 1 greater than or equal to candle 2
      && NormalizeDouble(CombinedHistory[CndleStart][Idx] ,7) >= NormalizeDouble(CombinedHistory[CndleStart + 1][Idx] ,7) 
      //candle 2 less than or equal to candle 3
      && NormalizeDouble(CombinedHistory[CndleStart + 1][Idx] ,7) <= NormalizeDouble(CombinedHistory[CndleStart + 2][Idx] ,7) 
      //candle 1 is negative, candle 2 is negative, candle 3 is negative
      && CombinedHistory[CndleStart][Idx] < 0 && CombinedHistory[CndleStart + 1][Idx] < 0 && CombinedHistory[CndleStart + 2][Idx] < 0
      )
   {
      //Print("TEST TEST PLOT INCREASING BRIGHT RED TO DARK RED");
      result = "PLOT INCREASING BRIGHT RED TO DARK RED";
   }
   //SELL STRATEGY, DARK RED TO BRIGHT RED
   if (
      OverallStrategy == "SELL_DK_RED_BR_RED"

      //candle 1 less than or equal to candle 2
      && NormalizeDouble(CombinedHistory[CndleStart][Idx] ,7) <= NormalizeDouble(CombinedHistory[CndleStart + 1][Idx] ,7) 
      //candle 2 greater than or equal to candle 3
      && NormalizeDouble(CombinedHistory[CndleStart + 1][Idx] ,7) >= NormalizeDouble(CombinedHistory[CndleStart + 2][Idx] ,7) 
      //candle 1 is negative, candle 2 is negative, candle 3 is negative
      && CombinedHistory[CndleStart][Idx] < 0 && CombinedHistory[CndleStart + 1][Idx] < 0 && CombinedHistory[CndleStart + 2][Idx] < 0
      )
   {
      //Print("TEST TEST PLOT DECREASING DARK RED TO BRIGHT RED");
      result = "PLOT INCREASING BRIGHT RED TO DARK RED";
   }


   //ENTRY LOGIC

  //BUY ENTRY, DARK GREEN TO BRIGHT GREEN
   if (
      BuyStrategyActive == true 
      && OverallStrategy == "BUY_DK_GREEN_BR_GREEN_ENTRY"

      && CombinedHistory[CndleStart][Idx] >  CombinedHistory[CndleStart + 1][Idx]
      && CombinedHistory[CndleStart + 1][Idx] > 0 
      )
   {
      result = "ENTER A BUY DARK GREEN BRIGHT GREEN";
   }

   //SELL ENTRY, BRIGHT GREEN TO DARK GREEN, POSITIVE M1
   if (
      SellStrategyActive == true 
      && OverallStrategy == "SELL_BR_GREEN_DK_GREEN_ENTRY"

      && CombinedHistory[CndleStart][Idx] <  CombinedHistory[CndleStart + 1][Idx]
      && CombinedHistory[CndleStart + 1][Idx] > 0 //don't care if plot 2 is decreasing positive or decreasing negative?
      )
   {
      result = "ENTER A SELL BRIGHT GREEN DARK GREEN";
   }
   else
   //SELL ENTRY, BRIGHT GREEN TO DARK GREEN, NEGATIVE M1
   if (
      SellStrategyActive == true 
      && OverallStrategy == "SELL_BR_GREEN_DK_GREEN_ENTRY"

      && CombinedHistory[CndleStart][Idx] >  CombinedHistory[CndleStart + 1][Idx]
      && CombinedHistory[CndleStart + 1][Idx] < 0 //don't care if plot 2 is decreasing positive or decreasing negative?
      )
   {
      //Print("xxxxxxxxxxxxxxxxSELL_BR_GREEN_DK_GREEN_ENTRY");
      result = "ENTER A SELL BRIGHT GREEN DARK GREEN";
   }

   //SELL ENTRY, DARK GREEN TO BRIGHT RED
   if (
      SellStrategyActive == true 
      && OverallStrategy == "SELL_DK_GREEN_BR_RED_ENTRY"

      && CombinedHistory[CndleStart][Idx] <  CombinedHistory[CndleStart + 1][Idx]
      && CombinedHistory[CndleStart + 1][Idx] < 0 //don't care if plot 2 is decreasing positive or decreasing negative?
      )
   {
      result = "ENTER A SELL DARK GREEN BRIGHT RED";
   }

   //BUY ENTRY, BRIGHT RED TO DARK RED
   if (
      BuyStrategyActive == true 
      && OverallStrategy == "BUY_BR_RED_DK_RED_ENTRY"

      && CombinedHistory[CndleStart][Idx] >  CombinedHistory[CndleStart + 1][Idx]
      && CombinedHistory[CndleStart + 1][Idx] < 0 //don't care if plot 2 is decreasing positive or decreasing negative?
      )
   {
      result = "ENTER A BUY BRIGHT RED DARK RED";
   }

   //SELL ENTRY, DARK RED TO BRIGHT RED
   if (
      SellStrategyActive == true 
      && OverallStrategy == "SELL_DK_RED_BR_RED_ENTRY"

      && CombinedHistory[CndleStart][Idx] <  CombinedHistory[CndleStart + 1][Idx]
      && CombinedHistory[CndleStart + 1][Idx] < 0 //don't care if plot 2 is decreasing positive or decreasing negative?
      )
   {
      //Print("TEST TEST ENTER A SELL DARK RED BRIGHT RED");
      result = "ENTER A SELL DARK RED BRIGHT RED";
   }

   //EXIT LOGIC

   //BUY EXIT, DARK GREEN TO BRIGHT GREEN
   if (
      OverallStrategy == "BUY_DK_GREEN_BR_GREEN_EXIT" &&
      CombinedHistory[CndleStart][Idx] < CombinedHistory[CndleStart + 1][Idx] 
      && CombinedHistory[CndleStart + 1][Idx] > 0 
      )
   {
      result = "EXIT A BUY DARK GREEN BRIGHT GREEN";
   }

   //SELL EXIT, BRIGHT GREEN TO DARK GREEN
   if (
      OverallStrategy == "SELL_BR_GREEN_DK_GREEN_EXIT" &&
      CombinedHistory[CndleStart][Idx] > CombinedHistory[CndleStart + 1][Idx] 
      && CombinedHistory[CndleStart + 1][Idx] < 0 
      )
   {
      result = "EXIT A SELL BRIGHT GREEN DARK GREEN";
   }

   //SELL EXIT, DARK GREEN TO BRIGHT RED
   if (
      OverallStrategy == "SELL_DK_GREEN_BR_RED_EXIT" &&
      CombinedHistory[CndleStart][Idx] > CombinedHistory[CndleStart + 1][Idx] 
      && CombinedHistory[CndleStart + 1][Idx] < 0 
      )
   {
      result = "EXIT A SELL DARK GREEN BRIGHT RED";
   }

   //BUY EXIT, BRIGHT RED TO DARK RED
   if (
      OverallStrategy == "BUY_BR_RED_DK_RED_EXIT" &&
      CombinedHistory[CndleStart][Idx] > CombinedHistory[CndleStart + 1][Idx] 
      && CombinedHistory[CndleStart + 1][Idx] > 0 
      )
   {
      result = "EXIT A BUY BRIGHT RED DARK RED";
   }

   //SELL EXIT, DARK RED TO BRIGHT RED
   if (
      OverallStrategy == "SELL_DK_RED_BR_RED_EXIT" &&
      CombinedHistory[CndleStart][Idx] > CombinedHistory[CndleStart + 1][Idx] 
      && CombinedHistory[CndleStart + 1][Idx] < 0 
      )
   {
      result = "EXIT A SELL DARK RED BRIGHT RED";
   }

   return result;
}


//DutoSunOverhaul

//DutoSun3_2

//bool TradeActive, BuyTradeActive, SellTradeActive;
bool TradeActive;

bool BrightRedToDarkRedM5Active, DarkRedToBrightRedM5Active;

bool DrRedToBrRedStgyActive;

bool BrightRedToDarkRedM1Active, DarkRedToBrightRedM1Active;

bool SellTypicalStgyActive, BuyTypicalStgyActive;


ENUM_SIGNAL_ENTRY DutoSun3_2Entry()
{  
    //SIGNAL_ENTRY_SELL
   
   if (
      (SignalEntrySellTypical() && TradeActive == false && SellTradeActive == false && SellTypicalStgyActive == false && DrRedToBrRedStgyActive == false)
      )
    {
      //macd, 1 min
      EntryData[0][7] = CombinedHistory[1][36];
      //bid price
      EntryData[0][10] = Bid;

      TradeActive = true; //flag to indicate that a sell or a buy trade is active
      SellTradeActive = true;
      SellTypicalStgyActive = true;
      SignalEntry = SIGNAL_ENTRY_SELL; 

      Print("Enter sell SellTypicalStgyActive: " + SellTypicalStgyActive);
    }

    //SIGNAL_ENTRY_BUY
   
   if (
      (SignalEntryBuyTypical() && TradeActive == false && BuyTradeActive == false && BuyTypicalStgyActive == false && DrRedToBrRedStgyActive == false)
      )
    {
      //macd, 1 min
      EntryData[0][7] = CombinedHistory[1][36];
      //bid price
      EntryData[0][10] = Bid;

      TradeActive = true; //flag to indicate that a sell or a buy trade is active
      BuyTradeActive = true;
      BuyTypicalStgyActive = true;
      SignalEntry = SIGNAL_ENTRY_BUY; 

      Print("Enter buy BuyTypicalStgyActive: " + BuyTypicalStgyActive);
    }

    /* if ((PlotChangedDrRedBrRedM5() == "DarkRedToBrightRedM5" && TradeActive == false && SellTradeActive == false && DrRedToBrRedStgyActive == false))
    {
      //macd, 1 min
      EntryData[0][7] = CombinedHistory[1][36];
      //bid price
      EntryData[0][10] = Bid;

      TradeActive = true; //flag to indicate that a sell or a buy trade is active
      SellTradeActive = true;
      DrRedToBrRedStgyActive = true;
      SignalEntry = SIGNAL_ENTRY_SELL; 

      //Print("TradeActive: " + TradeActive);
      //Print("SellTradeActive: " + SellTradeActive);
      Print("Enter sell DrRedToBrRedStgyActive: " + DrRedToBrRedStgyActive);
      //Print("SIGNAL_ENTRY_SELL DarkRedToBrightRedM5: ");
    } */

   return SignalEntry;
}

ENUM_SIGNAL_EXIT DutoSun3_2Exit()
{  
   // This is where you should insert your Exit Signal for SELL orders
   // Include a condition to open a buy order, the condition will have to set SignalExit=SIGNAL_EXIT_SELL

   if (

         (SignalExitSellTypical () && TradeActive == true && SellTradeActive == true && SellTypicalStgyActive == true && DrRedToBrRedStgyActive == false)
      )
   {
      TradeActive = false;
      SellTradeActive = false;
      SellTypicalStgyActive = false;
      SignalExit = SIGNAL_EXIT_SELL;

      //Print("SignalExit set to SIGNAL_EXIT_SELL typical: " + SignalExit);     
      //Print("TradeActive: " + TradeActive);  
      //Print("SellTradeActive: " + SellTradeActive);  
      Print("Exit SellTypicalStgyActive: " + SellTypicalStgyActive);  
   } 

   // This is where you should insert your Exit Signal for BUY orders
   // Include a condition to open a buy order, the condition will have to set SignalExit=SIGNAL_EXIT_SELL

   if (

         (SignalExitBuyTypical () && TradeActive == true && BuyTradeActive == true && BuyTypicalStgyActive == true && DrRedToBrRedStgyActive == false)
      )
   {
      TradeActive = false;
      BuyTradeActive = false;
      BuyTypicalStgyActive = false;
      SignalExit = SIGNAL_EXIT_BUY;

      //Print("SignalExit set to SIGNAL_EXIT_SELL typical: " + SignalExit);     
      //Print("TradeActive: " + TradeActive);  
      //Print("SellTradeActive: " + SellTradeActive);  
      Print("Exit BuyTypicalStgyActive: " + BuyTypicalStgyActive);  
   } 

   /* if ((PlotChangedBrRedDrRedM1 () == "BrightRedToDarkRedM1" && TradeActive == true && SellTradeActive == true && SellTypicalStgyActive == false && DrRedToBrRedStgyActive == true))
   {
      TradeActive = false;
      SellTradeActive = false;
      DrRedToBrRedStgyActive = false;
      SignalExit = SIGNAL_EXIT_SELL;
    
      //Print("TradeActive: " + TradeActive);  
      //Print("SellTradeActive: " + SellTradeActive); 
      Print("DrRedToBrRedStgyActive: " + DrRedToBrRedStgyActive);
      //Print("SIGNAL_EXIT_SELL DarkRedToBrightRedM5: " + SignalExit);
   } */

   return SignalExit;
}



string PlotChangedBrRedDrRedM5 ()
{
   string result = "";

      //plot 4 changed from bright red to dark red
      if (
       (
         BrightRedToDarkRedM5Active == false
         //M5
         && (CombinedHistory[1][29] > CombinedHistory[2][29]) 
         && (CombinedHistory[2][29] < CombinedHistory[3][29])
         && CombinedHistory[1][29] < 0
       )
      )
      {
         Print("M5");
         Print(
            NormalizeDouble(CombinedHistory[1][29] ,6) + " < " + NormalizeDouble(CombinedHistory[2][29] ,6) + 
            " && " + NormalizeDouble(CombinedHistory[3][29] ,6) + " > " + NormalizeDouble(CombinedHistory[2][29] ,6) +
            " && " + NormalizeDouble(CombinedHistory[1][29] ,6) + " < 0" 
         );

         result = "BrightRedToDarkRedM5";
         BrightRedToDarkRedM5Active = true;
         DarkRedToBrightRedM5Active = false;

         Print("Plot 4 changed to " + result);
      }

      return result;
}

string PlotChangedDrRedBrRedM5 ()
{
   string result = "";

   /* Print("beginning PlotChangedDrRedBrRedM5.");
   Print("DrRedToBrRedStgyActive: " + DrRedToBrRedStgyActive);

   Print("M5 RQMENTS");
   Print(CombinedHistory[2][29] > CombinedHistory[1][29]);//plot 4
   Print(CombinedHistory[2][29] > CombinedHistory[3][29]);//plot 4
   Print(CombinedHistory[1][29] < 0);//plot 4

   Print("M1 RQMENTS");
   Print(CombinedHistory[1][36] < 0);//macd
   Print(CombinedHistory[1][37] < 0);//macd
   Print(CombinedHistory[1][38] < 0);//macd
   Print(CombinedHistory[1][39] < 0);//macd

   Print("end."); */

   //plot 4 changed from dark red to bright red
      if (
       (
         DrRedToBrRedStgyActive == false
         //M5 RQMENTS
         && (CombinedHistory[2][29] > CombinedHistory[1][29]) 
         && (CombinedHistory[2][29] > CombinedHistory[3][29])
         && CombinedHistory[1][29] < 0
         //M1 RQMENTS
         && CombinedHistory[1][36] < 0
         && CombinedHistory[1][37] < CombinedHistory[2][37] && CombinedHistory[1][37] < 0
         && CombinedHistory[1][38] < CombinedHistory[2][38] && CombinedHistory[1][38] < 0
         && CombinedHistory[1][39] < CombinedHistory[2][39] && CombinedHistory[1][39] < 0
       )
      )
      {
         Print("M5");
         Print(
            NormalizeDouble(CombinedHistory[2][29] ,6) + " > " + NormalizeDouble(CombinedHistory[1][29] ,6) + 
            " && " + NormalizeDouble(CombinedHistory[2][29] ,6) + " > " + NormalizeDouble(CombinedHistory[2][29] ,6) +
            " && " + NormalizeDouble(CombinedHistory[1][29] ,6) + " < 0" 
         );

         result = "DarkRedToBrightRedM5";

         Print("Plot 4 M5 changed to " + result);       
      }

      return result;
}

string PlotChangedBrRedDrRedM1 ()
{
   string result = "";
   //bool result = false;

   /* Print("beginning PlotChangedBrRedDrRedM1.");
   Print("DrRedToBrRedStgyActive: " + DrRedToBrRedStgyActive);
   Print(CombinedHistory[1][37] > CombinedHistory[2][37]);
   Print(CombinedHistory[3][37] < CombinedHistory[2][37]);
   Print(CombinedHistory[1][37] < 0);
   Print("end."); */

      //plot 4 changed from bright red to dark red
      if (
       (
         DrRedToBrRedStgyActive == true

         /* //M5
         && (CombinedHistory[1][37] > CombinedHistory[2][37]) 
         && (CombinedHistory[2][37] < CombinedHistory[3][37])
         && CombinedHistory[1][37] < 0 */

         //M1
         && (CombinedHistory[2][36] < CombinedHistory[1][36]) 
         && (CombinedHistory[2][36] < CombinedHistory[3][36])
         && CombinedHistory[1][36] < 0
       )
      )
      {
         Print("M1");
         Print(
            NormalizeDouble(CombinedHistory[2][36] ,6) + " < " + NormalizeDouble(CombinedHistory[1][36] ,6) + 
            " && " + NormalizeDouble(CombinedHistory[2][36] ,6) + " < " + NormalizeDouble(CombinedHistory[3][36] ,6) +
            " && " + NormalizeDouble(CombinedHistory[1][36] ,6) + " < 0" 
         );

         result = "BrightRedToDarkRedM1";

         //Print("Plot 1 M1 changed to " + result);
         Print("MACD M1 changed to " + result);
      }

      return result;
}

bool SignalEntrySellTypical ()
{
   //enter a sell if the M5 chart has a red delta c and plots 2-3 are increasing negative 
   //AND if the M1 chart has a red delta c and plots 2-3 are negative
   //AND if the M1 macd peaks at green

   //SIGNAL_ENTRY_SELL TYPICAL
   if (
       SellTypicalStgyActive == false
       && SellTradeActive == false

       //1 MINUTE CANDLE HISTORY
       //CHART INDICATORS
       //delta c is red
       && 
       (CombinedHistory[1][35] == -1 //delta c, candle 1 is negative, 1 min
      
       //MACD AND PLOTS
       //MACD
       //macd peaks at green
       && CombinedHistory[1][36] < CombinedHistory[2][36] //macd, candle 1 less than candle 2, 1 min
       && CombinedHistory[3][36] < CombinedHistory[2][36] //macd, candle 3 less than candle 2, 1 min
       && CombinedHistory[1][36] > 0 && CombinedHistory[2][36] > 0 //macd, candle 1 and candle 2 positive, 1 min

       //PLOTS
       //plots 2-3 are negative      
       && CombinedHistory[1][37] < 0 //plot 2, candle 1 is negative, 1 min
       && CombinedHistory[1][38] < 0 //plot 3, candle 1 is negative, 1 min
       && CombinedHistory[1][39] < 0 //plot 4, candle 1 is negative, 1 min

       //5 MINUTE CANDLE HISTORY
       //CHART INDICATORS
       //delta c is red
       && CombinedHistory[1][25] == -1 //delta c, candle 1 is negative, 5 min

       //MACD AND PLOTS
       //PLOTS
       //plots 1-4 are increasing negative
        &&
         ( 
                  CombinedHistory[1][27] < CombinedHistory[2][27] && CombinedHistory[1][27] < 0
               && CombinedHistory[1][28] < CombinedHistory[2][28] && CombinedHistory[1][28] < 0
               && CombinedHistory[1][29] < CombinedHistory[2][29] && CombinedHistory[1][29] < 0  
         )
       )
       )
       {
         Print("SignalEntrySellTypical");
         return true;
       }
       else 
       {
         return false;
       }
}

bool SignalExitSellTypical ()
{
   //SIGNAL_EXIT_SELL TYPICAL
   if (
         //there is an active trade
         TradeActive == true
         && SellTypicalStgyActive == true

         //MACD AND PLOTS
         //MACD
         //macd peaks at red
         && 
         (
         CombinedHistory[1][36] > CombinedHistory[2][36] //macd, candle 1 greater than candle 2, 1 min
         && CombinedHistory[1][36] < 0 && CombinedHistory[2][36] < 0 //macd, candle 1 and candle 2 negative, 1 min
         )
         ||
         (CombinedHistory[1][27] > CombinedHistory[2][27] && CombinedHistory[1][27] < 0 )
      )
       {
         Print("SignalExitSellTypical");
         return true;
       }
       else 
       {
         return false;
       }
}

bool SignalEntryBuyTypical ()
{
   //enter a sell if the M5 chart has a red delta c and plots 2-3 are increasing negative 
   //AND if the M1 chart has a red delta c and plots 2-3 are negative
   //AND if the M1 macd peaks at green

   //SIGNAL_ENTRY_BUY TYPICAL
   if (
       BuyTypicalStgyActive == false
       && BuyTradeActive == false

       //1 MINUTE CANDLE HISTORY
       //CHART INDICATORS
       //delta c is red
       && 
       (CombinedHistory[1][35] == 1 //delta c, candle 1 is negative, 1 min
      
       //MACD AND PLOTS
       //MACD
       //macd peaks at green
       && CombinedHistory[1][36] > CombinedHistory[2][36] //macd, candle 1 less than candle 2, 1 min
       && CombinedHistory[3][36] > CombinedHistory[2][36] //macd, candle 3 less than candle 2, 1 min
       && CombinedHistory[1][36] < 0 && CombinedHistory[2][36] < 0 //macd, candle 1 and candle 2 positive, 1 min

       //PLOTS
       //plots 2-3 are negative      
       && CombinedHistory[1][37] > 0 //plot 2, candle 1 is negative, 1 min
       && CombinedHistory[1][38] > 0 //plot 3, candle 1 is negative, 1 min
       && CombinedHistory[1][39] > 0 //plot 4, candle 1 is negative, 1 min

       //5 MINUTE CANDLE HISTORY
       //CHART INDICATORS
       //delta c is red
       && CombinedHistory[1][25] == 1 //delta c, candle 1 is negative, 5 min

       //MACD AND PLOTS
       //PLOTS
       //plots 2-4 are increasing negative
        &&
         ( 
                  CombinedHistory[1][27] > CombinedHistory[2][27] && CombinedHistory[1][27] > 0
               && CombinedHistory[1][28] > CombinedHistory[2][28] && CombinedHistory[1][28] > 0
               && CombinedHistory[1][29] > CombinedHistory[2][29] && CombinedHistory[1][29] > 0  
         )
       )
       )
       {
         Print("SignalEntryBuyTypical");
         return true;
       }
       else 
       {
         return false;
       }
}

bool SignalExitBuyTypical ()
{
   //SIGNAL_EXIT_BUY TYPICAL
   if (
         //there is an active trade
         (TradeActive == true
         && BuyTypicalStgyActive == true)

         //MACD AND PLOTS
         //MACD
         //macd peaks at red
         && 
         (
              (CombinedHistory[1][36] < CombinedHistory[2][36] //macd, candle 1 greater than candle 2, 1 min
              && CombinedHistory[1][36] > 0 && CombinedHistory[2][36] > 0) //macd, candle 1 and candle 2 negative, 1 min       
              ||
              (CombinedHistory[1][27] < CombinedHistory[2][27] && CombinedHistory[1][27] > 0 )
         )
      )
       {
         Print("SignalExitBuyTypical");
         return true;
       }
       else 
       {
         return false;
       }
}

string PlotChangedDrRedBrRedM1 ()
{
   string result = "";

   //plot 4 changed from dark red to bright red
      if (
       (
         DarkRedToBrightRedM1Active = false
         //1 == 1
         //M1
         && (CombinedHistory[1][39] < CombinedHistory[2][39]) 
         && (CombinedHistory[2][39] > CombinedHistory[3][39])
         && CombinedHistory[1][39] < 0
       )
      )
      {
         Print("M1");
         Print(
            NormalizeDouble(CombinedHistory[1][39] ,6) + " < " + NormalizeDouble(CombinedHistory[2][39] ,6) + 
            " && " + NormalizeDouble(CombinedHistory[3][39] ,6) + " > " + NormalizeDouble(CombinedHistory[2][39] ,6) +
            " && " + NormalizeDouble(CombinedHistory[1][39] ,6) + " < 0" 
         );

         result = "DarkRedToBrightRedM1";
         DarkRedToBrightRedM1Active = true;
         BrightRedToDarkRedM1Active = false;

         Print("Plot 4 M1 changed to " + result);       
      }

      return result;
}

//DutoSun3_2

//////STRATEGIES END
   



