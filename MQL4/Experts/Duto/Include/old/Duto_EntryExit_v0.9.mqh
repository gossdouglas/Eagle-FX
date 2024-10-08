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
         //CombinedHistory[i][2] = FastMAHistoryBuffer[i];//fast moving average
         CombinedHistory[i][2] = NormalizeDouble(FastMAHistoryBuffer[i], 5);//fast moving average
         
         SlowMAHistoryBuffer[i] = iCustom(Symbol(),60, duto_chart_indicators, 1, i);
         CombinedHistory[i][3] = SlowMAHistoryBuffer[i];//slow moving average

         FiveFiftyMAHistoryBuffer[i] = iCustom(Symbol(),60, duto_chart_indicators, 4, i);
         CombinedHistory[i][4] = FiveFiftyMAHistoryBuffer[i];//550 moving average

         DeltaCollapsedPosHistoryBuffer[i] = iCustom(Symbol(),60, duto_chart_indicators, 5, i);
         DeltaCollapsedNegHistoryBuffer[i] = iCustom(Symbol(),60, duto_chart_indicators, 6, i);

         if (DeltaCollapsedPosHistoryBuffer[i] == 2147483647) {

            //strWriteLine2 = ",Negative";
            CombinedHistory[i][5] = -1;//delta collapsed negative
         }
         else {
            //strWriteLine2 = ",Positive";
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
         //"Candle " + i
         i
         + "," + iTime(Symbol(), 60, i) 

         + "," + DoubleToString(FastMAHistoryBuffer[i], 5)
         + "," + DoubleToString(SlowMAHistoryBuffer[i], 5)
         + "," + DoubleToString(FiveFiftyMAHistoryBuffer[i], 5)

         + strWriteLine2
         
         + "," + DoubleToString(MacdHistoryBuffer[i], 6)
         + "," + DoubleToString(MacdPlot2HistoryBuffer[i], 6)
         + "," + DoubleToString(MacdPlot3HistoryBuffer[i], 6)
         + "," + DoubleToString(MacdPlot4HistoryBuffer[i], 6)
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

            //strWriteLine2 = ",Negative";
            CombinedHistory[i][15] = -1;//delta collapsed negative
         }
         else {
            //strWriteLine2 = ",Positive";
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
         
         + "," + DoubleToString(MacdHistoryBuffer[i], 6)
         + "," + DoubleToString(MacdPlot2HistoryBuffer[i], 6)
         + "," + DoubleToString(MacdPlot3HistoryBuffer[i], 6)
         + "," + DoubleToString(MacdPlot4HistoryBuffer[i], 6)
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

            //strWriteLine2 = ",Negative";
            CombinedHistory[i][25] = -1;//delta collapsed negative
         }
         else {
            //strWriteLine2 = ",Positive";
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
         //",Candle " + i
         "," + i
         + "," + iTime(Symbol(), 5, i) 

         + "," + DoubleToString(FastMAHistoryBuffer[i], 5)
         + "," + DoubleToString(SlowMAHistoryBuffer[i], 5)
         + "," + DoubleToString(FiveFiftyMAHistoryBuffer[i], 5)

         + strWriteLine2
         
         + "," + DoubleToString(MacdHistoryBuffer[i], 6)
         + "," + DoubleToString(MacdPlot2HistoryBuffer[i], 6)
         + "," + DoubleToString(MacdPlot3HistoryBuffer[i], 6)
         + "," + DoubleToString(MacdPlot4HistoryBuffer[i], 6)
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

            //strWriteLine2 = ",Negative";
            CombinedHistory[i][35] = -1;//delta collapsed negative
         }
         else {
            //strWriteLine2 = ",Positive";
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
         + "," + iTime(Symbol(), 1, i) 

         + "," + DoubleToString(FastMAHistoryBuffer[i], 5)
         + "," + DoubleToString(SlowMAHistoryBuffer[i], 5)
         + "," + DoubleToString(FiveFiftyMAHistoryBuffer[i], 5)

         + strWriteLine2
         
         + "," + DoubleToString(MacdHistoryBuffer[i], 6)
         + "," + DoubleToString(MacdPlot2HistoryBuffer[i], 6)
         + "," + DoubleToString(MacdPlot3HistoryBuffer[i], 6)
         + "," + DoubleToString(MacdPlot4HistoryBuffer[i], 6)

         + "\r\n";

         //write a line of strings to a file
         FileWriteString(fileHandleIndicatorData, strWriteLine, StringLen(strWriteLine));

         /* //check combined history data with output
         Print("check combined history data with output");
         string combinedHistoryOutput = "";

         for (int col = 0; col <= 29; col++)
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

   //Print("ReturnSignalEntryToEvaluateEntry()");

   // Declaring the variables for the entry and exit check
   SignalEntry = SIGNAL_ENTRY_NEUTRAL;

   //strategy to be used for entry
   //SignalEntry = OneMinuteDeltaCTransitionEntry();
   SignalEntry = ReDotuEntry();

   return SignalEntry;
}

//ENUM_SIGNAL_ENTRY ReturnSignalExitToEvaluateExit()
ENUM_SIGNAL_EXIT ReturnSignalExitToEvaluateExit()

{
   // Declaring the variables for the entry and exit check
   SignalExit = SIGNAL_EXIT_NEUTRAL;

   //strategy to be used for exit
   //SignalExit = FifteenMinuteApexExit();
   //SignalExit = OneMinuteDeltaCTransitionExit();

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

////REDOTU
double EntryData[2][11];//

ENUM_SIGNAL_ENTRY ReDotuEntry()
{  
   GetIndicatorHistory(32, 50);//get 1 minute indicator history for the last 20 candles

   // This is where you should insert your Entry Signal for SELL orders
   // Include a condition to open a sell order, the condition will have to set SignalEntry=SIGNAL_ENTRY_SELL  
   if (
      //1 minute candle history
      //chart indicators
      CombinedHistory[1][35] == -1 //delta c, candle 1 is negative, 1 min
      
      //plots
      && CombinedHistory[1][36] > 0 && CombinedHistory[2][36] > 0 //macd, candle 1 is positive, 1 min
      && CombinedHistory[2][36] > CombinedHistory[1][36] //
      && CombinedHistory[1][37] < 0 //plot 2, candle 1 is negative, 1 min
      && CombinedHistory[1][38] < 0 //plot 3, candle 1 is negative, 1 min
      && CombinedHistory[1][39] < 0 //plot 4, candle 1 is negative, 1 min

      //5 minute candle history
      //chart indicators
      && CombinedHistory[1][25] == -1 //delta c, candle 1 is negative, 5 min
      //plots
      && CombinedHistory[1][26] < 0 //macd, candle 1 is positive, 5 min
      && CombinedHistory[1][27] < 0 //plot 2, candle 1 is negative, 5 min
      && CombinedHistory[1][28] < 0 //plot 3, candle 1 is negative, 5 min
      && CombinedHistory[1][29] < 0 //plot 4, candle 1 is negative, 5 min
      )
   {
      EntryData[0][7] = CombinedHistory[1][36];
      EntryData[0][10] = Bid;

      SignalEntry = SIGNAL_ENTRY_SELL; 
      Print("EntryData[0][7]: " + EntryData[0][7]);    
      Print("EntryData[0][10]: " + EntryData[0][10]);   
   }

   // // This is where you should insert your Entry Signal for BUY orders
   // // Include a condition to open a sell order, the condition will have to set SignalEntry=SIGNAL_ENTRY_SELL  
    if (
       //1 minute candle history
       //chart indicators
       CombinedHistory[1][35] == 1 //delta c, candle 1 is negative, 1 min
      
       //plots
       && CombinedHistory[1][36] < 0 && CombinedHistory[2][36] < 0 //macd, candle 1 is positive, 1 min
       && CombinedHistory[2][36] < CombinedHistory[1][36] //

       && CombinedHistory[1][37] > 0 //plot 2, candle 1 is negative, 1 min
       && CombinedHistory[1][38] > 0 //plot 3, candle 1 is negative, 1 min
       && CombinedHistory[1][39] > 0 //plot 4, candle 1 is negative, 1 min

       //5 minute candle history
       //chart indicators
       && CombinedHistory[1][25] == 1 //delta c, candle 1 is negative, 5 min
       //plots
       && CombinedHistory[1][26] > 0 //macd, candle 1 is positive, 5 min
       && CombinedHistory[1][27] > 0 //plot 2, candle 1 is negative, 5 min
       && CombinedHistory[1][28] > 0 //plot 3, candle 1 is negative, 5 min
       && CombinedHistory[1][29] > 0 //plot 4, candle 1 is negative, 5 min
       )
    {
       EntryData[1][7] = CombinedHistory[1][36];
       EntryData[1][10] = Ask;

       SignalEntry = SIGNAL_ENTRY_BUY; 
       Print("EntryData[1][7]: " + EntryData[1][7]); 
       Print("EntryData[0][10]: " + EntryData[1][10]); 
    }

   return SignalEntry;
}

ENUM_SIGNAL_EXIT OneMinuteDeltaCTransitionExit()
{  
   // This is where you should insert your Exit Signal for SELL orders
   // Include a condition to open a buy order, the condition will have to set SignalExit=SIGNAL_EXIT_SELL
   if (
      //1 minute candle history
      //chart indicators
      //CombinedHistory[1][35] == -1 //delta c, candle 1 is negative, 1 min
      
      //plots
      (CombinedHistory[1][36] < 0 && CombinedHistory[2][36] < 0 && CombinedHistory[3][36] < 0 //macd, candle 1 is positive, 1 min
      && CombinedHistory[1][36] < -EntryData[0][7]
      && Ask < EntryData[0][10] //current price is less than the price it was entered at

      && CombinedHistory[1][36] > CombinedHistory[2][36] //
      && CombinedHistory[3][36] > CombinedHistory[2][36] )
      || 
      (CombinedHistory[1][38] > 0 //plot 2, candle 1 is negative, 1 min
      && CombinedHistory[2][38] < 0) //plot 2, candle 1 is negative, 1 min
      )
   {
      SignalExit = SIGNAL_EXIT_SELL;     
   }

   // This is where you should insert your Exit Signal for BUY orders
   // Include a condition to open a buy order, the condition will have to set SignalExit=SIGNAL_EXIT_SELL
   if (
      //1 minute candle history
      //chart indicators
      //CombinedHistory[1][35] == -1 //delta c, candle 1 is negative, 1 min
      
      //plots
      (CombinedHistory[1][36] > 0 && CombinedHistory[2][36] > 0 && CombinedHistory[3][36] > 0 //macd, candle 1 is positive, 1 min
      && CombinedHistory[1][36] > EntryData[1][7] //current macd is greater than the macd it was entered at
      && Bid > EntryData[1][10] //current price is greater than the price it was entered at

      && CombinedHistory[1][36] < CombinedHistory[2][36] //
      && CombinedHistory[3][36] < CombinedHistory[2][36] )
      || 
      //(CombinedHistory[1][38] < 0 //plot 2, candle 1 is negative, 1 min
      //&& CombinedHistory[2][38] > 0) //plot 2, candle 1 is negative, 1 min
      (CombinedHistory[1][37] < 0 //plot 2, candle 1 is negative, 1 min
      && CombinedHistory[2][37] > 0) //plot 2, candle 1 is negative, 1 min
      )
   {
      SignalExit = SIGNAL_EXIT_BUY;     
   }
   
   return SignalExit;
}
////REDOTU


//////STRATEGIES END
   



