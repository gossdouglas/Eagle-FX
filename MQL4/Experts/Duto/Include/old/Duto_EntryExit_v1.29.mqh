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
   //DutoWind_Strategy();
   //check for an entry
   SignalEntry = DutoWind_Entry();

   return SignalEntry;
}

ENUM_SIGNAL_EXIT ReturnSignalExitToEvaluateExit()

{
   // Declaring the variables for the entry and exit check
   SignalExit = SIGNAL_EXIT_NEUTRAL;

   //strategy to be used for exit
   //SignalExit = DutoSun3_2Exit();
   SignalExit = DutoWind_Exit();

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

//DutoWind

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

string CurrentStrategy;
bool SellStrategyActive, BuyStrategyActive, NeutralStrategyActive;

bool BuyDkGrBrGrStrategyActive, SellBrGrDkGrStrategyActive;
bool SellDkGrBrRdStrategyActive, BuyBrRdDkRdStrategyActive;
bool SellDkRdBrRdStrategyActive, BuyDkRdBrGrStrategyActive;

bool SellTradeActive, BuyTradeActive, TradeActive;

void DutoWind_Strategy()
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
      && 
      //BuyStrategyActive == false
      BuyDkGrBrGrStrategyActive == false
      )
   {
      SellStrategyActive = false;
      BuyStrategyActive = true;
      NeutralStrategyActive = false;

      BuyDkGrBrGrStrategyActive = true;
      SellBrGrDkGrStrategyActive = false;
      SellDkGrBrRdStrategyActive = false;
      BuyBrRdDkRdStrategyActive = false;
      SellDkRdBrRdStrategyActive = false;
      BuyDkRdBrGrStrategyActive = false;

      Print("A BUY STRATEGY IN EFFECT. SellStrategyActive: " + SellStrategyActive + " BuyStrategyActive: " + BuyStrategyActive 
      + " NeutralStrategyActive: " + NeutralStrategyActive);
      Print("PLOT INCREASING DARK GREEN TO BRIGHT GREEN POSITIVE. BuyDkGrBrGrStrategyActive: " + BuyDkGrBrGrStrategyActive);
   }
   else
   //SELL STRATEGY CHECK FOR BRIGHT GREEN TO DARK GREEN
   if (
      (AskThePlots(28, 1, 1, "SELL_BR_GREEN_DK_GREEN") == "PLOT DECREASING BRIGHT GREEN TO DARK GREEN") 
      && 
      //SellStrategyActive == false
      SellBrGrDkGrStrategyActive == false
      )
   {
      SellStrategyActive = true;
      BuyStrategyActive = false;
      NeutralStrategyActive = false;

      BuyDkGrBrGrStrategyActive = false;
      SellBrGrDkGrStrategyActive = true;
      SellDkGrBrRdStrategyActive = false;
      BuyBrRdDkRdStrategyActive = false;
      SellDkRdBrRdStrategyActive = false;
      BuyDkRdBrGrStrategyActive = false;

      Print("A SELL STRATEGY IN EFFECT. SellStrategyActive: " + SellStrategyActive + " BuyStrategyActive: " + BuyStrategyActive 
      + " NeutralStrategyActive: " + NeutralStrategyActive);
      Print("PLOT DECREASING BRIGHT GREEN TO DARK GREEN POSITIVE. SellBrGrDkGrStrategyActive: " + SellBrGrDkGrStrategyActive);
   }
   else
   //SELL STRATEGY CHECK FOR DARK GREEN TO BRIGHT RED
   if (
      (AskThePlots(28, 1, 1, "SELL_DK_GREEN_BR_RED") == "PLOT DECREASING DARK GREEN TO BRIGHT RED") 
      && 
      //SellStrategyActive == false
      SellDkGrBrRdStrategyActive == false
      )
   {
      SellStrategyActive = true;
      BuyStrategyActive = false;
      NeutralStrategyActive = false;

      BuyDkGrBrGrStrategyActive = false;
      SellBrGrDkGrStrategyActive = false;
      SellDkGrBrRdStrategyActive = true;
      BuyBrRdDkRdStrategyActive = false;
      SellDkRdBrRdStrategyActive = false;
      BuyDkRdBrGrStrategyActive = false;

      Print("A SELL STRATEGY IN EFFECT. SellStrategyActive: " + SellStrategyActive + " BuyStrategyActive: " + BuyStrategyActive 
      + " NeutralStrategyActive: " + NeutralStrategyActive);
      Print("PLOT DECREASING DARK GREEN TO BRIGHT RED. SellDkGrBrRdStrategyActive: " + SellDkGrBrRdStrategyActive);
   }
   else
   //BUY STRATEGY CHECK FOR BRIGHT RED TO DARK RED
   if (
      (AskThePlots(28, 1, 1, "BUY_BR_RED_DK_RED") == "PLOT INCREASING BRIGHT RED TO DARK RED") 
      && BuyBrRdDkRdStrategyActive == false
      //SellStrategyActive == false
      )
   {
      SellStrategyActive = false;
      BuyStrategyActive = true;
      NeutralStrategyActive = false;

      BuyDkGrBrGrStrategyActive = false;
      SellBrGrDkGrStrategyActive = false;
      SellDkGrBrRdStrategyActive = false;
      BuyBrRdDkRdStrategyActive = true;
      SellDkRdBrRdStrategyActive = false;
      BuyDkRdBrGrStrategyActive = false;

      Print("A BUY STRATEGY IN EFFECT. SellStrategyActive: " + SellStrategyActive + " BuyStrategyActive: " + BuyStrategyActive 
      + " NeutralStrategyActive: " + NeutralStrategyActive);
      Print("PLOT INCEASING BRIGHT RED TO DARK RED. BuyBrRdDkRdStrategyActive: " + BuyBrRdDkRdStrategyActive);
   }
   else
   //SELL STRATEGY CHECK FOR DARK RED TO BRIGHT RED
   if (
      (AskThePlots(28, 1, 1, "SELL_DK_RED_BR_RED") == "PLOT DECREASING DARK RED TO BRIGHT RED") 
      && 
      //SellStrategyActive == false
      SellDkRdBrRdStrategyActive == false
      )
   {
      SellStrategyActive = true;
      BuyStrategyActive = false;
      NeutralStrategyActive = false;

      BuyDkGrBrGrStrategyActive = false;
      SellBrGrDkGrStrategyActive = false;
      SellDkGrBrRdStrategyActive = false;
      BuyBrRdDkRdStrategyActive = false;
      SellDkRdBrRdStrategyActive = true;
      BuyDkRdBrGrStrategyActive = false;

      Print("A SELL STRATEGY IN EFFECT. SellStrategyActive: " + SellStrategyActive + " BuyStrategyActive: " + BuyStrategyActive 
      + " NeutralStrategyActive: " + NeutralStrategyActive);
      Print("PLOT DECREASING DARK RED TO BRIGHT RED. SellDkRdBrRdStrategyActive: " + SellDkRdBrRdStrategyActive);
   }
   //BUY STRATEGY CHECK FOR DARK RED TO BRIGHT GREEN
   if (
      (AskThePlots(28, 1, 1, "BUY_DK_RED_BR_GREEN") == "PLOT INCREASING DARK RED TO BRIGHT GREEN") 
      && 
      //BuyStrategyActive == false //this line is troublesome. it likely needs to die.
      BuyDkRdBrGrStrategyActive == false
      )
   {
      SellStrategyActive = false;
      BuyStrategyActive = true;
      NeutralStrategyActive = false;

      BuyDkGrBrGrStrategyActive = false;
      SellBrGrDkGrStrategyActive = false;
      SellDkGrBrRdStrategyActive = false;
      BuyBrRdDkRdStrategyActive = false;
      SellDkRdBrRdStrategyActive = false;
      BuyDkRdBrGrStrategyActive = true;

      Print("A BUY STRATEGY IN EFFECT. SellStrategyActive: " + SellStrategyActive + " BuyStrategyActive: " + BuyStrategyActive 
      + " NeutralStrategyActive: " + NeutralStrategyActive);
      Print("PLOT INCREASING DARK RED TO BRIGHT GREEN POSITIVE. BuyDkRdBrGrStrategyActive: " + BuyDkRdBrGrStrategyActive);
   }

   //Comment(StringFormat("Show prices\nAsk = %G\nBid = %G = %d",Ask,Bid));
   Comment("Current Strategy : " + CurrentStrategy);
}

ENUM_SIGNAL_ENTRY DutoWind_Entry()
{
   
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
      //SignalEntry = SIGNAL_ENTRY_BUY;
   }

   //SELL ENTRY, BRIGHT GREEN TO DARK GREEN
   if (
         (AskThePlots(38, 1, 1, "SELL_BR_GREEN_DK_GREEN_ENTRY") == "ENTER A SELL BRIGHT GREEN DARK GREEN") 
         //MACD DECREASING FROM POSITIVE TO NEGATIVE
         //(AskThePlots(36, 1, 1, "SELL_BR_GREEN_DK_GREEN_ENTRY") == "ENTER A SELL BRIGHT GREEN DARK GREEN")
         //SAFETY TRADE
         //(AskThePlots(36, 1, 1, "SELL_ST_BR_GREEN_DK_GREEN_ENTRY") == "ENTER A ST SELL BRIGHT GREEN DARK GREEN")
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
      //SignalEntry = SIGNAL_ENTRY_SELL;
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
      //SignalEntry = SIGNAL_ENTRY_SELL;
   }

   //BUY ENTRY, DARK RED TO BRIGHT GREEN
   if (
         (AskThePlots(38, 1, 1, "BUY_DK_RED_BR_GREEN_ENTRY") == "ENTER A BUY DARK RED BRIGHT GREEN") 
      && BuyStrategyActive == true 
      && BuyTradeActive == false

      && BuyDkRdBrGrStrategyActive == true
      )
   {
      BuyTradeActive = true;

      Print("ENTER A BUY, DARK RED TO BRIGHT GREEN. " +
      "SellStrategyActive: " + SellStrategyActive + 
      " BuyTradeActive: " + BuyTradeActive + 
      " BuyDkRdBrGrStrategyActive: " + BuyDkRdBrGrStrategyActive);
      //SignalEntry = SIGNAL_ENTRY_BUY;
   }

   //SignalEntry = SIGNAL_ENTRY_NEUTRAL;

   return SignalEntry;
}

ENUM_SIGNAL_EXIT DutoWind_Exit()
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

   //BUY EXIT, DARK RED TO BRIGHT GREEN
   if (
      AskThePlots(36, 1, 1, "BUY_DK_RED_BR_GREEN_EXIT") == "EXIT A BUY DARK RED BRIGHT GREEN"
      && BuyStrategyActive == true 
      && BuyTradeActive == true

      && BuyDkRdBrGrStrategyActive == true
      )
   {
      BuyTradeActive = false;
      BuyDkRdBrGrStrategyActive = false;

      Print("EXIT A BUY, DARK RED TO BRIGHT GREEN. SellStrategyActive: " + SellStrategyActive + " BuyStrategyActive: " + BuyStrategyActive);
      SignalExit = SIGNAL_EXIT_BUY;
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
      CurrentStrategy = OverallStrategy; 
      //Print("ask the plots PLOT INCREASING DARK GREEN TO BRIGHT GREEN");
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
      CurrentStrategy = OverallStrategy; 
      //Print("ask the plots PLOT DECREASING BRIGHT GREEN TO DARK GREEN");
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
      CurrentStrategy = OverallStrategy; 
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
      CurrentStrategy = OverallStrategy; 
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
      CurrentStrategy = OverallStrategy; 
      //Print("TEST TEST PLOT DECREASING DARK RED TO BRIGHT RED");
      result = "PLOT DECREASING DARK RED TO BRIGHT RED";
   }
   //BUY STRATEGY, DARK RED TO BRIGHT GREEN
   if (
      OverallStrategy == "BUY_DK_RED_BR_GREEN"

      //candle 1 greater than or equal to candle 2
      && NormalizeDouble(CombinedHistory[CndleStart][Idx] ,7) >= NormalizeDouble(CombinedHistory[CndleStart + 1][Idx] ,7) 
      //candle 2 greater than or equal to candle 3
      && NormalizeDouble(CombinedHistory[CndleStart + 1][Idx] ,7) >= NormalizeDouble(CombinedHistory[CndleStart + 2][Idx] ,7) 
      //candle 1 is positive, candle 2 is negative, candle 3 is negative
      && CombinedHistory[CndleStart][Idx] > 0 && CombinedHistory[CndleStart + 1][Idx] < 0 && CombinedHistory[CndleStart + 2][Idx] < 0
      )
   {
      CurrentStrategy = OverallStrategy; 
      //Print("TEST TEST PLOT INCREASING DARK RED TO BRIGHT GREEN");
      result = "PLOT INCREASING DARK RED TO BRIGHT GREEN";
   }


   //ENTRY LOGIC

  /* //BUY ENTRY, DARK GREEN TO BRIGHT GREEN
   if (
      BuyStrategyActive == true 
      && OverallStrategy == "BUY_DK_GREEN_BR_GREEN_ENTRY"

      && CombinedHistory[CndleStart][Idx] >  CombinedHistory[CndleStart + 1][Idx]
      //&& CombinedHistory[CndleStart + 1][Idx] > 0 
      && CombinedHistory[CndleStart][Idx] > 0 && CombinedHistory[CndleStart + 1][Idx] < 0
      )
   {
      Print("ENTRY LOGIC-- ENTER A BUY DARK GREEN BRIGHT GREEN");
      result = "ENTER A BUY DARK GREEN BRIGHT GREEN";
   } */

   //SELL ENTRY, BRIGHT GREEN TO DARK GREEN, POSITIVE M1
   if (
      SellStrategyActive == true 
      && OverallStrategy == "SELL_BR_GREEN_DK_GREEN_ENTRY"

      && CombinedHistory[CndleStart][Idx] <  CombinedHistory[CndleStart + 1][Idx]
      //&& CombinedHistory[CndleStart + 1][Idx] > 0 //don't care if plot 2 is decreasing positive or decreasing negative?
      && CombinedHistory[CndleStart][Idx] < 0 && CombinedHistory[CndleStart + 1][Idx] > 0
      )
   {
      Print("ENTRY LOGIC-- ENTER A SELL BRIGHT GREEN DARK GREEN");
      result = "ENTER A SELL BRIGHT GREEN DARK GREEN";
   }

   //SELL ENTRY SAFETY TRADE, BRIGHT GREEN TO DARK GREEN, POSITIVE M1
   if (
      SellStrategyActive == true 
      && OverallStrategy == "SELL_ST_BR_GREEN_DK_GREEN_ENTRY"
      && SellBrGrDkGrStrategyActive == true

      && CombinedHistory[CndleStart][Idx] <  CombinedHistory[CndleStart + 1][Idx]
      && CombinedHistory[CndleStart][Idx] < 0 && CombinedHistory[CndleStart + 1][Idx] > 0
      && BarColorCount(Idx, "POSITIVE") <= 6
      )
   {   
      Print(BarColorCount(Idx, "POSITIVE"));  
      //Print("ENTRY LOGIC-- ENTER A SELL BRIGHT GREEN DARK GREEN");
      result = "ENTER A ST SELL BRIGHT GREEN DARK GREEN";
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

   //BUY ENTRY, DARK RED TO BRIGHT GREEN
   if (
      BuyStrategyActive == true 
      && OverallStrategy == "BUY_DK_RED_BR_GREEN_ENTRY"

      && CombinedHistory[CndleStart][Idx] <  CombinedHistory[CndleStart + 1][Idx]
      && CombinedHistory[CndleStart + 1][Idx] > 0 //don't care if plot 2 is decreasing positive or decreasing negative?
      )
   {
      result = "ENTER A BUY DARK RED BRIGHT GREEN";
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

   //BUY EXIT, DARK RED TO BRIGHT GREEN
   if (
      OverallStrategy == "BUY_DK_RED_BR_GREEN_EXIT" &&
      CombinedHistory[CndleStart][Idx] > CombinedHistory[CndleStart + 1][Idx] 
      && CombinedHistory[CndleStart + 1][Idx] > 0 
      )
   {
      result = "EXIT A BUY DARK RED BRIGHT GREEN";
   }

   return result;
}

int BarColorCount (int Idx, string PosNeg){

   //Print("ENTER BarColorCount");

   int count = 2;

   if (PosNeg == "NEGATIVE" && CombinedHistory[count + 1][Idx] < 0 )
   {
      Print("CANDLE 3 IS NEGATIVE: " + CombinedHistory[count + 1][Idx]);

      /* do 
     { 

      count++; // without this operator an infinite loop will appear! 
     } 
      while(CombinedHistory[count + 1][Idx] < 0); */
   }
   else
   if (PosNeg == "POSITIVE" && CombinedHistory[count + 1][Idx] > 0)
   {
      //Print("CANDLE 3 IS POSITIVE: " + CombinedHistory[count + 1][Idx]);
      do 
     { 
      //Print("CANDLE " + (count + 1) + " IS POSITIVE: " + CombinedHistory[count + 1][Idx]);
      count++; // without this operator an infinite loop will appear! 
     } 
      while(CombinedHistory[count + 1][Idx] > 0);
   }

   return count;
}

//DutoWind

//////STRATEGIES END
   



