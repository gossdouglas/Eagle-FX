//-PROPERTIES-//
// Properties help the software look better when you load it in MT4
// Provide more information and details
// This is what you see in the About tab when you load an indicator or an Expert Advisor
#property link "https://www.earnforex.com/metatrader-expert-advisors/expert-advisor-template/"
#property version "1.00"
#property strict
#property copyright "EarnForex.com - 2020-2021"
#property description "This is a template for a generic Automated EA"
#property description " "
#property description "WARNING : You use this software at your own risk."
#property description "The creator of these plugins cannot be held responsible for any damage or loss."
#property description " "
#property description "Find More on EarnForex.com"
// You can add an icon for when the EA loads on chart but it's not necessary
// The commented line below is an example of icon, icon must be in the MQL4/Files folder and have a ico extension
// #property icon          "\\Files\\EF-Icon-64x64px.ico"

//-INCLUDES-//
// Include allows to import code from another file
// In the following instance the file has to be placed in the MQL4/Include Folder
#include <MQLTA ErrorHandling.mqh>


//-ENUMERATIVE VARIABLES-//
// Enumerative variables are useful to associate numerical values to easy to remember strings
// It is similar to constants but also helps if the variable is set from the input page of the EA
// The text after the // is what you see in the input paramenters when the EA loads
// It is good practice to place all the enumberative at the start
enum ENUM_HOUR
{
   h00 = 00, // 00:00
   h01 = 01, // 01:00
   h02 = 02, // 02:00
   h03 = 03, // 03:00
   h04 = 04, // 04:00
   h05 = 05, // 05:00
   h06 = 06, // 06:00
   h07 = 07, // 07:00
   h08 = 08, // 08:00
   h09 = 09, // 09:00
   h10 = 10, // 10:00
   h11 = 11, // 11:00
   h12 = 12, // 12:00
   h13 = 13, // 13:00
   h14 = 14, // 14:00
   h15 = 15, // 15:00
   h16 = 16, // 16:00
   h17 = 17, // 17:00
   h18 = 18, // 18:00
   h19 = 19, // 19:00
   h20 = 20, // 20:00
   h21 = 21, // 21:00
   h22 = 22, // 22:00
   h23 = 23, // 23:00
};

enum ENUM_SIGNAL_ENTRY{
   SIGNAL_ENTRY_NEUTRAL=0,    //SIGNAL ENTRY NEUTRAL
   SIGNAL_ENTRY_BUY=1,        //SIGNAL ENTRY BUY
   SIGNAL_ENTRY_SELL=-1,      //SIGNAL ENTRY SELL
};

enum ENUM_SIGNAL_EXIT{
   SIGNAL_EXIT_NEUTRAL=0,     //SIGNAL EXIT NEUTRAL
   SIGNAL_EXIT_BUY=1,         //SIGNAL EXIT BUY
   SIGNAL_EXIT_SELL=-1,        //SIGNAL EXIT SELL
   SIGNAL_EXIT_ALL=2,         //SIGNAL EXIT ALL
};

ENUM_SIGNAL_ENTRY SignalEntry = SIGNAL_ENTRY_NEUTRAL; // Entry signal variable
ENUM_SIGNAL_EXIT SignalExit=SIGNAL_EXIT_NEUTRAL;         //Exit signal variable

enum ENUM_TRADING_ALLOW_DIRECTION
{
   TRADING_ALLOW_BOTH = 0,  // ALLOW BOTH BUY AND SELL
   TRADING_ALLOW_BUY = 1,   // ALLOW BUY ONLY
   TRADING_ALLOW_SELL = -1, // ALLOW SELL ONLY
};

enum ENUM_RISK_BASE
{
   RISK_BASE_EQUITY = 1,     // EQUITY
   RISK_BASE_BALANCE = 2,    // BALANCE
   RISK_BASE_FREEMARGIN = 3, // FREE MARGIN
};

enum ENUM_RISK_DEFAULT_SIZE
{
   RISK_DEFAULT_FIXED = 1, // FIXED SIZE
   RISK_DEFAULT_AUTO = 2,  // AUTOMATIC SIZE BASED ON RISK
};

enum ENUM_MODE_SL
{
   SL_FIXED = 0, // FIXED STOP LOSS
   SL_AUTO = 1,  // AUTOMATIC STOP LOSS
};

enum ENUM_MODE_TP
{
   TP_FIXED = 0, // FIXED TAKE PROFIT
   TP_AUTO = 1,  // AUTOMATIC TAKE PROFIT
};

enum ENUM_MODE_SL_BY
{
   SL_BY_POINTS = 0, // STOP LOSS PASSED IN POINTS
   SL_BY_PRICE = 1,  // STOP LOSS PASSED BY PRICE
};

//********************************************************************************************************
//DUTO EA SPECIFIC INPUTS
//********************************************************************************************************

//selected time frame
enum ENUM_UPPER_TIME_FRAME
{
   TIME_FRAME_H1 = 0, // H1
   TIME_FRAME_M15 = 10, // M15
   TIME_FRAME_M5 = 20, // M5
};

//selected trade exit plot
enum ENUM_EXIT_PLOT
{
   PLOT_1 = 6, // MACD
   PLOT_2 = 7, // Plot 2
};

/* //selected allow opposite dark on plot 2
enum ENUM_ALLOW_DK_STRAT2
{
   ALLOW_DK_STRAT2_TRUE = 1, // YES
   ALLOW_DK_STRAT2_FALSE = 0, // NO
}; */

//upper left information section
input string Comment_5 = "=========="; // Duto Specific Settings
input ENUM_UPPER_TIME_FRAME UpperTimeFrame = TIME_FRAME_M5; // Upper time frame
input double BarColorCountThreshold = 3.5;  // BarColorCount Threshold
input double BarCountThreshold = 20;  // Bar Count Threshold
input int LookBackCount = 20;
input ENUM_EXIT_PLOT TradeExitPlot = 6; // Trade Exit Plot
// Allow Entry if the plots are dark but favorable
input bool AllowStrat2Dark = false; //Allow Strat Dark
input int TradePendingTimeout = 5; //Trade Pending Timeout
input double TradePendingMacdSP = .9;

//********************************************************************************************************
//DUTO EA SPECIFIC VARIABLES
//********************************************************************************************************

//only allows an evaluation to be made if LogIndicatorData has been executed at least once
bool StartupFlag;
//string that will be written to the chart window
string SettingsComments;
//string that will be written to the chart window
string CandleComments;
//string that will be written to the chart window
string PipComments;

//STRATEGY AND TRADE VARIABLES
double EntryData[2][11];
string CurrentStrategy;
bool SellStrategyActive, BuyStrategyActive, NeutralStrategyActive;

bool BuyDkGrBrGrStrategyActive, SellBrGrDkGrStrategyActive;
bool SellDkGrBrRdStrategyActive, BuyBrRdDkRdStrategyActive;
bool SellDkRdBrRdStrategyActive, BuyDkRdBrGrStrategyActive;

bool SellTradeActive, BuyTradeActive, TradeActive;
bool SellTradesValid, BuyTradesValid, TradePending;
int TradePendingTimeoutCount;

bool BuySafetyTrade2Strategy, SellSafetyTrade2Strategy, NeutralSafetyTrade2Strategy;

int SymmetryObjectRunning = 0;

//HISTORY ARRAYS

//chart indicator history arrays
double FastMAHistoryBuffer[], SlowMAHistoryBuffer[], FiveFiftyMAHistoryBuffer[], DeltaCollapsedPosHistoryBuffer[], DeltaCollapsedNegHistoryBuffer[];
//MACD indicator history arrays
double MacdHistoryBuffer[],  MacdPlot2HistoryBuffer[], MacdPlot3HistoryBuffer[], MacdPlot4HistoryBuffer[];
//sniper indicator history array
int SniperHistoryBuffer[];

//a two dimensional array that stored indicator data from all time frames
//each time frame has 10 measurements
double CombinedHistoryPrev[1][100];
double CombinedHistory[1][100];
//track whether a macd is trending bright or dark
double BrightTickCount, DarkTickCount;

//LogIndicatorData() variables
string indicatorName = "_Custom\\Duto\\macd_color_indicator_plot1_v0.11";
string duto_chart_indicators = "_Custom\\Duto\\duto_chart_indicators_v0.6";
string duto_chart_moving_averages = "_Custom\\Duto\\duto_mas";

string SniperBlue = "_Custom\\Duto\\SniperBlue";
string SniperPink = "_Custom\\Duto\\SniperPink";
string SniperPurple = "_Custom\\Duto\\SniperPurple";

string strWriteLine, strWriteLine2 = "";
int fileHandleIndicatorData;
int periodArray[] = {60, 15, 5};

//SNIPER VARIABLES
double LastHighest, LastLowest;
bool SniperCockedHigh, SniperCockedLow, SniperCockedNeutral;
double SniperDayValue;
int SniperObjectRunning = 0;

//********************************************************************************************************
//-INPUT PARAMETERS-//
// The input parameters are the ones that can be set by the user when launching the EA
// If you place a comment following the input variable this will be shown as description of the field
//********************************************************************************************************

// General input parameters
input string Comment_0 = "==========";                            // Risk Management Settings
input ENUM_RISK_DEFAULT_SIZE RiskDefaultSize = RISK_DEFAULT_AUTO; // Position Size Mode
input double DefaultLotSize = 1;                                  // Position Size (if fixed or if no stop loss defined)
input ENUM_RISK_BASE RiskBase = RISK_BASE_BALANCE;                // Risk Base
input int MaxRiskPerTrade = 2;                                    // Percentage To Risk Each Trade
input double MinLotSize = 0.01;                                   // Minimum Position Size Allowed
input double MaxLotSize = 100;                                    // Maximum Position Size Allowed
input double PSARStopStep = 0.04;                                 // Stop Loss PSAR Step
input double PSARStopMax = 0.4;                                   // Stop Loss PSAR Max

input string Comment_1 = "==========";                            // Trading Hours Settings
input bool UseTradingHours = false;                               // Limit Trading Hours
input ENUM_HOUR TradingHourStart = h07;                           // Trading Start Hour (Broker Server Hour)
input ENUM_HOUR TradingHourEnd = h19;                             // Trading End Hour (Broker Server Hour)

input string Comment_2 = "==========";                            // Stop Loss And Take Profit Settings
input ENUM_MODE_SL StopLossMode = SL_FIXED;                       // Stop Loss Mode
input int DefaultStopLoss = 0;                                    // Default Stop Loss In Points (0=No Stop Loss)
input int MinStopLoss = 0;                                        // Minimum Allowed Stop Loss In Points
input int MaxStopLoss = 5000;                                     // Maximum Allowed Stop Loss In Points
input ENUM_MODE_TP TakeProfitMode = TP_FIXED;                     // Take Profit Mode
input int DefaultTakeProfit = 0;                                  // Default Take Profit In Points (0=No Take Profit)
input int MinTakeProfit = 0;                                      // Minimum Allowed Take Profit In Points
input int MaxTakeProfit = 5000;                                   // Maximum Allowed Take Profit In Points

input string Comment_3 = "=========="; // Trailing Stop Settings
input bool UseTrailingStop = false;    // Use Trailing Stop

input string Comment_4 = "=========="; // Additional Settings
input int MagicNumber = 0;             // Magic Number For The Orders Opened By This EA
input string OrderNote = "";           // Comment For The Orders Opened By This EA
input int Slippage = 5;                // Slippage in points
input int MaxSpread = 100;             // Maximum Allowed Spread To Trade In Points

//********************************************************************************************************
//-GLOBAL VARIABLES-//
// The viables included in this section are global, hence they can be used in any part of the code
// It is useful to add a comment to remember what is the variable for
//********************************************************************************************************

bool IsPreChecksOk = false;      // Indicates if the pre checks are satisfied
bool IsNewCandle = false;        // Indicates if this is a new candle formed
bool IsSpreadOK = false;         // Indicates if the spread is low enough to trade
bool IsOperatingHours = false;   // Indicates if it is possible to trade at the current time (server time)
bool IsTradedThisBar = false;    // Indicates if an order was already executed in the current candle

double TickValue = 0;            // Value of a tick in account currency at 1 lot
double LotSize = 0;              // Lot size for the position

int OrderOpRetry = 10;           // Number of attempts to retry the order submission
int TotalOpenOrders = 0;         // Number of total open orders
int TotalOpenBuy = 0;            // Number of total open buy orders
int TotalOpenSell = 0;           // Number of total open sell orders
int StopLossBy = SL_BY_POINTS;   // How the stop loss is passed for the lot size calculation

//********************************************************************************************************

//-NATIVE MT4 EXPERT ADVISOR RUNNING FUNCTIONS-//

//********************************************************************************************************

// OnInit is executed once, when the EA is loaded
// OnInit is also executed if the time frame or symbol for the chart is changed
int OnInit()
{
   // It is useful to set a function to check the integrity of the initial parameters and call it as first thing
   CheckPreChecks();
   // If the initial pre checks have something wrong, stop the program
   if (!IsPreChecksOk)
   {
      OnDeinit(INIT_FAILED);
      return (INIT_FAILED);
   }
   // Function to initialize the values of the global variables
   InitializeVariables();
   /* // Function to initialize the logging of history
   InitializeLogging(); */

   // Function to initialize the 
   InitializeEASettingsComments();

   // If everything is ok the function returns successfully and the control is passed to a timer or the OnTike function
   return (INIT_SUCCEEDED);
}

// The OnDeinit function is called just before terminating the program
void OnDeinit(const int reason)
{
   // You can include in this function something you want done when the EA closes
   // For example clean the chart form graphical objects, write a report to a file or some kind of alert

   //FileClose(fileHandleIndicatorData); 
}

// The OnTick function is triggered every time MT4 receives a price change for the symbol in the chart
void OnTick()
{
   // Re-initialize the values of the global variables at every run
   InitializeVariables();

   InitializeEAPipComments();

   /* // Re-initialize the EA running comments at every tick
   InitializeEACandleComments() */

   // ScanOrders scans all the open orders and collect statistics, if an error occurs it skips to the next price change
   if (!ScanOrders())
      return;
   // CheckNewBar checks if the price change happened at the start of a new bar
   CheckNewBar();
   // CheckOperationHours checks if the current time is in the operating hours
   CheckOperationHours();
   // CheckSpread checks if the spread is above the maximum spread allowed
   CheckSpread();
   // CheckTradedThisBar checks if there was already a trade executed in the current candle
   CheckTradedThisBar();
   // EvaluateExit contains the code to decide if there is an exit signal
   EvaluateExit();
   // ExecuteExit executes the exit in case there is an exit signal
   ExecuteExit();
   // Scan orders again in case some where closed, if an error occurs it skips to the next price change
   if (!ScanOrders())
      return;
   // Execute Trailing Stop
   ExecuteTrailingStop();
   // EvaluateEntry contains the code to decide if there is an entry signal
   EvaluateEntry();
   // ExecuteEntry executes the entry in case there is an entry signal
   ExecuteEntry();
}

//-CUSTOM EA FUNCTIONS-//

// Perform integrity checks when the EA is loaded
void CheckPreChecks()
{
   IsPreChecksOk = true;
   if (!IsTradeAllowed())
   {
      IsPreChecksOk = false;
      Print("Live Trading is not enabled, please enable it in MT4 and chart settings");
      return;
   }
   if (DefaultStopLoss < MinStopLoss || DefaultStopLoss > MaxStopLoss)
   {
      IsPreChecksOk = false;
      Print("Default Stop Loss must be between Minimum and Maximum Stop Loss Allowed");
      return;
   }
   if (DefaultTakeProfit < MinTakeProfit || DefaultTakeProfit > MaxTakeProfit)
   {
      IsPreChecksOk = false;
      Print("Default Take Profit must be between Minimum and Maximum Take Profit Allowed");
      return;
   }
   if (DefaultLotSize < MinLotSize || DefaultLotSize > MaxLotSize)
   {
      IsPreChecksOk = false;
      Print("Default Lot Size must be between Minimum and Maximum Lot Size Allowed");
      return;
   }
   if (Slippage < 0)
   {
      IsPreChecksOk = false;
      Print("Slippage must be a positive value");
      return;
   }
   if (MaxSpread < 0)
   {
      IsPreChecksOk = false;
      Print("Maximum Spread must be a positive value");
      return;
   }
   if (MaxRiskPerTrade < 0 || MaxRiskPerTrade > 100)
   {
      IsPreChecksOk = false;
      Print("Maximum Risk Per Trade must be a percentage between 0 and 100");
      return;
   }
}

// Initialize variables
void InitializeVariables()
{
   IsNewCandle = false;
   IsTradedThisBar = false;
   IsOperatingHours = false;
   IsSpreadOK = false;

   LotSize = DefaultLotSize;
   TickValue = 0;

   TotalOpenBuy = 0;
   TotalOpenSell = 0;
   TotalOpenOrders = 0;

   SignalEntry = SIGNAL_ENTRY_NEUTRAL;
   SignalExit = SIGNAL_EXIT_NEUTRAL;
}

// Evaluate if there is an entry signal, called from the OnTickEvent
void EvaluateEntry()
{
   SignalEntry = SIGNAL_ENTRY_NEUTRAL;

   /* if (!IsSpreadOK)
      return; // If the spread is too high don't give an entry signal

   if (IsTradedThisBar)
      return; // If you don't want to execute multiple trades in the same bar

   if (TotalOpenOrders > 0)
      return; // If there are already open orders and you don't want to open more */

   // whether a new candle has been started is based on the chart that is shown
   if (IsNewCandle)
   {
      // Re-initialize the EA candle comments at every new candle
      InitializeEACandleComments();

      //log data and build the CombinedHistory array
      LogIndicatorData();
      //evaluate for a strategy
      DutoWind_SelectedStrategy();
      //
      EvaluateLastHighestLowest();
      WriteTextToRight();

      //evaluate the sniper
      EvaluateSniper();
      //evaluate symmetry
      EvaluateSymmetry(UpperTimeFrame + 10 + 6, "BUY_BR_RED_DK_RED", 2);

      StartupFlag = true;
      //Comment(StringFormat("Show prices\nAsk = %G\nBid = %G = %d",Ask,Bid)); 
   }

   //this logic only allows an evaluation to be made if LogIndicatorData has been executed at least once
   if (StartupFlag == true && IsSpreadOK && !IsTradedThisBar 
      && (!TotalOpenOrders > 0))
   { 
      //set candle 0 data on each pip
      SetCandleZeroIndicatorData();
      // evaluate for a signal entry
      SignalEntry = ReturnSignalEntryToEvaluateEntry();
      
   }

   Comment(SettingsComments + CandleComments + PipComments); 
}

// Execute entry if there is an entry signal
void ExecuteEntry()
{
   //Print("BuyTradePending: " + BuyTradePending);
   //Print("> .9: " + (CombinedHistory[0][UpperTimeFrame + 10 + 6] > .9));

   /* // If there is no entry signal no point to continue
   if (SignalEntry == SIGNAL_ENTRY_NEUTRAL)
   //if (TradePending != true)
      return; */

   int Operation;
   double OpenPrice = 0;
   double StopLossPrice = 0;
   double TakeProfitPrice = 0;
   // If there is a Buy entry signal
   if (SignalEntry == SIGNAL_ENTRY_BUY)
   //if (!IsTradedThisBar && BuyTradesValid == true && !TotalOpenOrders && EntryConditionsOk("BUY", 1))
   {
      RefreshRates();     // Get latest rates
      Operation = OP_BUY; // Set the operation to BUY
      OpenPrice = Ask;    // Set the open price to Ask price
      // If the Stop Loss is fixed and the default stop loss is set
      if (StopLossMode == SL_FIXED && DefaultStopLoss > 0)
      {
         StopLossPrice = OpenPrice - DefaultStopLoss * Point;
      }
      // If the Stop Loss is automatic
      if (StopLossMode == SL_AUTO)
      {
         // Set the Stop Loss to the custom stop loss price
         StopLossPrice = StopLossPriceCalculate();
      }
      // If the Take Profix price is fixed and defined
      if (TakeProfitMode == TP_FIXED && DefaultTakeProfit > 0)
      {
         TakeProfitPrice = OpenPrice + DefaultTakeProfit * Point;
      }
      // If the Take Profit is automatic
      if (TakeProfitMode == TP_AUTO)
      {
         // Set the Take Profit to the custom take profit price
         TakeProfitPrice = TakeProfitCalculate();
      }
      // Normalize the digits for the float numbers
      OpenPrice = NormalizeDouble(OpenPrice, Digits);
      StopLossPrice = NormalizeDouble(StopLossPrice, Digits);
      TakeProfitPrice = NormalizeDouble(TakeProfitPrice, Digits);

      //TradePending = false;
      //BuyTradesValid = false;
      BuyTradeActive = true;

      // Submit the order
      SendOrder(Operation, Symbol(), OpenPrice, StopLossPrice, TakeProfitPrice);
   }
   
   if (SignalEntry == SIGNAL_ENTRY_SELL)
   //if (!IsTradedThisBar && SellTradesValid == true && !TotalOpenOrders && EntryConditionsOk("SELL", 1))
   {
      RefreshRates();      // Get latest rates

      Operation = OP_SELL; // Set the operation to SELL
      //Operation = OP_SELLSTOP; // Set the operation to SELL

      OpenPrice = Bid;     // Set the open price to Ask price
      // If the Stop Loss is fixed and the default stop loss is set
      if (StopLossMode == SL_FIXED && DefaultStopLoss > 0)
      {
         StopLossPrice = OpenPrice + DefaultStopLoss * Point;
      }
      // If the Stop Loss is automatic
      if (StopLossMode == SL_AUTO)
      {
         // Set the Stop Loss to the custom stop loss price
         StopLossPrice = StopLossPriceCalculate();
      }
      // If the Take Profix price is fixed and defined
      if (TakeProfitMode == TP_FIXED && DefaultTakeProfit > 0)
      {
         TakeProfitPrice = OpenPrice - DefaultTakeProfit * Point;
      }
      // If the Take Profit is automatic
      if (TakeProfitMode == TP_AUTO)
      {
         // Set the Take Profit to the custom take profit price
         TakeProfitPrice = TakeProfitCalculate();
      }
      // Normalize the digits for the float numbers
      OpenPrice = NormalizeDouble(OpenPrice, Digits);
      StopLossPrice = NormalizeDouble(StopLossPrice, Digits);
      TakeProfitPrice = NormalizeDouble(TakeProfitPrice, Digits);

      TradePending = false;
      SellTradesValid = false;
      SellTradeActive = true;
      
      // Submit the order
      SendOrder(Operation, Symbol(), OpenPrice, StopLossPrice, TakeProfitPrice);
   }
}

// Evaluate if there is an exit signal, called from the OnTickEvent
void EvaluateExit()
{
   SignalExit = SIGNAL_EXIT_NEUTRAL;

   // whether a new candle has been started is based on the chart that is shown
   if (IsNewCandle)
   {
      // Print("new candle in EvaluateEntry at: " + iTime(Symbol(), 1, 0));
      // log data and build the CombinedHistory array
      LogIndicatorData();
      StartupFlag = true;
   }

   //this logic only allows an evaluation to be made if LogIndicatorData has been executed at least once
   if (StartupFlag == true)
   {
      // evaluate for a signal entry
      SignalExit = ReturnSignalExitToEvaluateExit();
   }
}

// Execute exit if there is an exit signal
void ExecuteExit()
{
   // If there is no Exit Signal no point to continue the routine
   if (SignalExit == SIGNAL_EXIT_NEUTRAL)
      return;
   // If there is an exit signal for all orders
   if (SignalExit == SIGNAL_EXIT_ALL)
   {
      // Close all orders
      CloseAll(OP_ALL);
   }
   // If there is an exit signal for BUY order
   if (SignalExit == SIGNAL_EXIT_BUY)
   {
      // Close all BUY orders
      CloseAll(OP_BUY);
   }
   // If there is an exit signal for SELL orders
   if (SignalExit == SIGNAL_EXIT_SELL)
   {
      // Close all SELL orders
      CloseAll(OP_SELL);
   }
}

// Execute Trailing Stop to limit losses and lock in profits
void ExecuteTrailingStop()
{
   // If the option is off then exit
   if (!UseTrailingStop)
      return;
   // If there are no open orders no point to continue the code
   if (TotalOpenOrders == 0)
      return;
   // if(!IsNewCandle) return;      //If you only want to do the stop trailing once at the beginning of a new candle
   // Scan all the orders to see if some needs a stop loss update
   for (int i = 0; i < OrdersTotal(); i++)
   {
      // If there is a problem reading the order print the error, exit the function and return false
      if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES) == false)
      {
         int Error = GetLastError();
         string ErrorText = GetLastErrorText(Error);
         Print("ERROR - Unable to select the order - ", Error, " - ", ErrorText);
         return;
      }
      // If the order is not for the instrument on chart we can ignore it
      if (OrderSymbol() != Symbol())
         continue;
      // If the order has Magic Number different from the Magic Number of the EA then we can ignore it
      if (OrderMagicNumber() != MagicNumber)
         continue;
      // Define current values
      RefreshRates();
      double SLPrice = NormalizeDouble(OrderStopLoss(), Digits);       // Current Stop Loss price for the order
      double TPPrice = NormalizeDouble(OrderTakeProfit(), Digits);     // Current Take Profit price for the order
      double Spread = MarketInfo(Symbol(), MODE_SPREAD) * Point;       // Current Spread for the instrument
      double StopLevel = MarketInfo(Symbol(), MODE_STOPLEVEL) * Point; // Minimum distance between current price and stop loss

      // If it is a buy order then trail stop for buy orders
      if (OrderType() == OP_BUY)
      {
         // Include code to trail the stop for buy orders
         double NewSLPrice = 0;

         // This is where you should include the code to assign a new value to the STOP LOSS
         double PSARCurr = iSAR(Symbol(), PERIOD_CURRENT, PSARStopStep, PSARStopMax, 0);
         NewSLPrice = PSARCurr;

         double NewTPPrice = TPPrice;
         // Normalize the price before the submission
         NewSLPrice = NormalizeDouble(NewSLPrice, Digits);
         // If there is no new stop loss set then skip to next order
         if (NewSLPrice == 0)
            continue;
         // If the new stop loss price is lower than the previous then skip to next order, we only move the stop closer to the price and not further away
         if (NewSLPrice <= SLPrice)
            continue;
         // If the distance between the current price and the new stop loss is not enough then skip to next order
         // This allows to avoid error 130 when trying to update the order
         if (Bid - NewSLPrice < StopLevel)
            continue;
         // Submit the update
         ModifyOrder(OrderTicket(), OrderOpenPrice(), NewSLPrice, NewTPPrice);
      }
      // If it is a sell order then trail stop for sell orders
      if (OrderType() == OP_SELL)
      {
         // Include code to trail the stop for sell orders
         double NewSLPrice = 0;

         // This is where you should include the code to assign a new value to the STOP LOSS
         double PSARCurr = iSAR(Symbol(), PERIOD_CURRENT, PSARStopStep, PSARStopMax, 0);
         NewSLPrice = PSARCurr;

         double NewTPPrice = TPPrice;
         // Normalize the price before the submission
         NewSLPrice = NormalizeDouble(NewSLPrice, Digits);
         // If there is no new stop loss set then skip to next order
         if (NewSLPrice == 0)
            continue;
         // If the new stop loss price is higher than the previous then skip to next order, we only move the stop closer to the price and not further away
         if (NewSLPrice >= SLPrice)
            continue;
         // If the distance between the current price and the new stop loss is not enough then skip to next order
         // This allows to avoid error 130 when trying to update the order
         if (NewSLPrice - Ask < StopLevel)
            continue;
         // Submit the update
         ModifyOrder(OrderTicket(), OrderOpenPrice(), NewSLPrice, NewTPPrice);
      }
   }
   return;
}

// Check and return if the spread is not too high
void CheckSpread()
{
   // Get the current spread in points, the (int) transforms the double coming from MarketInfo into an integer to avoid a warning when compiling
   int SpreadCurr = (int)MarketInfo(Symbol(), MODE_SPREAD);
   if (SpreadCurr <= MaxSpread)
   {

      IsSpreadOK = true;
   }
   else
   {
      IsSpreadOK = false;
   }

   PipComments = PipComments + "IsSpreadOK: " + IsSpreadOK + "--SpreadCurr: " + SpreadCurr + 
   "--MaxSpread: " + MaxSpread + "\n";

   //Print("SpreadCurr: " + SpreadCurr + "MaxSpread: " + MaxSpread);
   //Print("IsSpreadOK: " + IsSpreadOK);
}

// Check and return if it is operation hours or not
void CheckOperationHours()
{
   // If we are not using operating hours then IsOperatingHours is true and I skip the other checks
   if (!UseTradingHours)
   {
      IsOperatingHours = true;
      return;
   }
   // Check if the current hour is between the allowed hours of operations, if so IsOperatingHours is set true
   if (TradingHourStart == TradingHourEnd && Hour() == TradingHourStart)
      IsOperatingHours = true;
   if (TradingHourStart < TradingHourEnd && Hour() >= TradingHourStart && Hour() <= TradingHourEnd)
      IsOperatingHours = true;
   if (TradingHourStart > TradingHourEnd && ((Hour() >= TradingHourStart && Hour() <= 23) || (Hour() <= TradingHourEnd && Hour() >= 0)))
      IsOperatingHours = true;
}

///*
// Check if it is a new bar
datetime NewBarTime = TimeCurrent();
void CheckNewBar()
{
   /* Print("NewBarTime:" + NewBarTime);
   Print("Time[0]:" + Time[0]); */

   // NewBarTime contains the open time of the last bar known
   // if that open time is the same as the current bar then we are still in the current bar, otherwise we are in a new bar
   if (NewBarTime == Time[0])
      IsNewCandle = false;
   else
   {
      NewBarTime = Time[0];
      IsNewCandle = true;
   }
}
///*

// Check if there was already an order open this bar
datetime LastBarTraded;
void CheckTradedThisBar()
{
   // LastBarTraded contains the open time the last trade
   // if that open time is in the same bar as the current then IsTradedThisBar is true
   if (iBarShift(Symbol(), PERIOD_CURRENT, LastBarTraded) == 0)
      IsTradedThisBar = true;
   else
      IsTradedThisBar = false;
}

// Lot Size Calculator
void LotSizeCalculate(double SL = 0)
{
   // If the position size is dynamic
   if (RiskDefaultSize == RISK_DEFAULT_AUTO)
   {
      // If the stop loss is not zero then calculate the lot size
      if (SL != 0)
      {
         double RiskBaseAmount = 0;
         // TickValue is the value of the individual price increment for 1 lot of the instrument, expressed in the account currenty
         TickValue = MarketInfo(Symbol(), MODE_TICKVALUE);
         // Define the base for the risk calculation depending on the parameter chosen
         if (RiskBase == RISK_BASE_BALANCE)
            RiskBaseAmount = AccountBalance();
         if (RiskBase == RISK_BASE_EQUITY)
            RiskBaseAmount = AccountEquity();
         if (RiskBase == RISK_BASE_FREEMARGIN)
            RiskBaseAmount = AccountFreeMargin();
         // Calculate the Position Size
         LotSize = (RiskBaseAmount * MaxRiskPerTrade / 100) / (SL * TickValue);
      }
      // If the stop loss is zero then the lot size is the default one
      if (SL == 0)
      {
         LotSize = DefaultLotSize;
      }
   }
   // Normalize the Lot Size to satisfy the allowed lot increment and minimum and maximum position size
   LotSize = MathFloor(LotSize / MarketInfo(Symbol(), MODE_LOTSTEP)) * MarketInfo(Symbol(), MODE_LOTSTEP);
   // Limit the lot size in case it is greater than the maximum allowed by the user
   if (LotSize > MaxLotSize)
      LotSize = MaxLotSize;
   // Limit the lot size in case it is greater than the maximum allowed by the broker
   if (LotSize > MarketInfo(Symbol(), MODE_MAXLOT))
      LotSize = MarketInfo(Symbol(), MODE_MAXLOT);
   // If the lot size is too small then set it to 0 and don't trade
   if (LotSize < MinLotSize || LotSize < MarketInfo(Symbol(), MODE_MINLOT))
      LotSize = 0;
}

// Stop Loss Price Calculation if dynamic
double StopLossPriceCalculate()
{
   double StopLossPrice = 0;
   // Include a value for the stop loss, ideally coming from an indicator
   double PSARCurr = iSAR(Symbol(), PERIOD_CURRENT, PSARStopStep, PSARStopMax, 0);
   StopLossPrice = PSARCurr;

   return StopLossPrice;
}

// Take Profit Price Calculation if dynamic
double TakeProfitCalculate()
{
   double TakeProfitPrice = 0;
   // Include a value for the take profit, ideally coming from an indicator
   return TakeProfitPrice;
}

// Send Order Function adjusted to handle errors and retry multiple times
void SendOrder(int Command, string Instrument, double OpenPrice, double SLPrice, double TPPrice, datetime Expiration = 0)
{
   // Retry a number of times in case the submission fails
   for (int i = 1; i <= OrderOpRetry; i++)
   {
      // Set the color for the open arrow for the order
      color OpenColor = clrBlueViolet;
      if (Command == OP_BUY)
      {
         OpenColor = clrChartreuse;
      }
      if (Command == OP_SELL)
      {
         OpenColor = clrDarkTurquoise;
      }
      // Calculate the position size, if the lot size is zero then exit the function
      double SLPoints = 0;
      // If the Stop Loss price is set then find the points of distance between open price and stop loss price, and round it
      if (SLPrice > 0)
         MathCeil(MathAbs(OpenPrice - SLPrice) / Point);
      // Call the function to calculate the position size
      LotSizeCalculate(SLPoints);
      // If the position size is zero then exit and don't submit any orderInit
      if (LotSize == 0)
         return;
      // Submit the order
      int res = OrderSend(Instrument, Command, LotSize, OpenPrice, Slippage, NormalizeDouble(SLPrice, Digits), NormalizeDouble(TPPrice, Digits), OrderNote, MagicNumber, Expiration, OpenColor);
      // If the submission is successful print it in the log and exit the function
      if (res)
      {
         Print("TRADE - OPEN SUCCESS - Order ", res, " submitted: Command ", Command, " Volume ", LotSize, " Open ", OpenPrice, " Stop ", SLPrice, " Take ", TPPrice, " Expiration ", Expiration);
         break;
      }
      // If the submission failed print the error
      else
      {
         Print("TRADE - OPEN FAILED - Order ", res, " submitted: Command ", Command, " Volume ", LotSize, " Open ", OpenPrice, " Stop ", SLPrice, " Take ", TPPrice, " Expiration ", Expiration);
         int Error = GetLastError();
         string ErrorText = GetLastErrorText(Error);
         Print("ERROR - NEW - error sending order, return error: ", Error, " - ", ErrorText);
      }
   }
   return;
}

// Modify Order Function adjusted to handle errors and retry multiple times
void ModifyOrder(int Ticket, double OpenPrice, double SLPrice, double TPPrice)
{
   // Try to select the order by ticket number and print the error if failed
   if (OrderSelect(Ticket, SELECT_BY_TICKET) == false)
   {
      int Error = GetLastError();
      string ErrorText = GetLastErrorText(Error);
      Print("ERROR - SELECT TICKET - error selecting order ", Ticket, " return error: ", Error);
      return;
   }
   // Normalize the digits for stop loss and take profit price
   SLPrice = NormalizeDouble(SLPrice, Digits);
   TPPrice = NormalizeDouble(TPPrice, Digits);
   // Try to submit the changes multiple times
   for (int i = 1; i <= OrderOpRetry; i++)
   {
      // Submit the change
      bool res = OrderModify(Ticket, OpenPrice, SLPrice, TPPrice, 0, Blue);
      // If the change is successful print the result and exit the function
      if (res)
      {
         Print("TRADE - UPDATE SUCCESS - Order ", Ticket, " new stop loss ", SLPrice, " new take profit ", TPPrice);
         break;
      }
      // If the change failed print the error with additional information to troubleshoot
      else
      {
         int Error = GetLastError();
         string ErrorText = GetLastErrorText(Error);
         Print("ERROR - UPDATE FAILED - error modifying order ", Ticket, " return error: ", Error, " - ERROR - ", ErrorText, " - Open=", OpenPrice,
               " Old SL=", OrderStopLoss(), " Old TP=", OrderTakeProfit(),
               " New SL=", SLPrice, " New TP=", TPPrice, " Bid=", MarketInfo(OrderSymbol(), MODE_BID), " Ask=", MarketInfo(OrderSymbol(), MODE_ASK));
      }
   }
   return;
}

// Close Single Order Function adjusted to handle errors and retry multiple times
void CloseOrder(int Ticket, double Lots, double CurrentPrice)
{
   // Try to close the order by ticket number multiple times in case of failure
   for (int i = 1; i <= OrderOpRetry; i++)
   {
      // Send the close command
      bool res = OrderClose(Ticket, Lots, CurrentPrice, Slippage, Red);
      // If the close was successful print the resul and exit the function
      if (res)
      {
         Print("TRADE - CLOSE SUCCESS - Order ", Ticket, " closed at price ", CurrentPrice);
         break;
      }
      // If the close failed print the error
      else
      {
         int Error = GetLastError();
         string ErrorText = GetLastErrorText(Error);
         Print("ERROR - CLOSE FAILED - error closing order ", Ticket, " return error: ", Error, " - ", ErrorText);
      }
   }
   return;
}

// Close All Orders of a specified type
const int OP_ALL = -1; // Constant to define the additional OP_ALL command which is the reference to all type of orders
void CloseAll(int Command)
{
   // If the command is OP_ALL then run the CloseAll function for both BUY and SELL orders
   if (Command == OP_ALL)
   {
      CloseAll(OP_BUY);
      CloseAll(OP_SELL);
      return;
   }
   double ClosePrice = 0;
   // Scan all the orders to close them individually
   // NOTE that the for loop scans from the last to the first, this is because when we close orders the list of orders is updated
   // hence the for loop would skip orders if we scan from first to last
   for (int i = OrdersTotal() - 1; i >= 0; i--)
   {
      // First select the order individually to get its details, if the selection fails print the error and exit the function
      if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES) == false)
      {
         Print("ERROR - Unable to select the order - ", GetLastError());
         break;
      }
      // Check if the order is for the current symbol and was opened by the EA and is the type to be closed
      if (OrderMagicNumber() == MagicNumber && OrderSymbol() == Symbol() && OrderType() == Command)
      {
         // Define the close price
         RefreshRates();
         if (Command == OP_BUY)
            ClosePrice = Bid;
         if (Command == OP_SELL)
            ClosePrice = Ask;
         // Get the position size and the order identifier (ticket)
         double Lots = OrderLots();
         int Ticket = OrderTicket();
         // Close the individual order
         CloseOrder(Ticket, Lots, ClosePrice);
      }
   }
}

// Scan all orders to find the ones submitted by the EA
// NOTE This function is defined as bool because we want to return true if it is successful and false if it fails
bool ScanOrders()
{
   // Scan all the orders, retrieving some of the details
   for (int i = 0; i < OrdersTotal(); i++)
   {
      // If there is a problem reading the order print the error, exit the function and return false
      if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES) == false)
      {
         int Error = GetLastError();
         string ErrorText = GetLastErrorText(Error);
         Print("ERROR - Unable to select the order - ", Error, " - ", ErrorText);
         return false;
      }
      // If the order is not for the instrument on chart we can ignore it
      if (OrderSymbol() != Symbol())
         continue;
      // If the order has Magic Number different from the Magic Number of the EA then we can ignore it
      if (OrderMagicNumber() != MagicNumber)
         continue;
      // If it is a buy order then increment the total count of buy orders
      if (OrderType() == OP_BUY)
         TotalOpenBuy++;
      // If it is a sell order then increment the total count of sell orders
      if (OrderType() == OP_SELL)
         TotalOpenSell++;
      // Increment the total orders count
      TotalOpenOrders++;
      // Find what is the open time of the most recent trade and assign it to LastBarTraded
      // this is necessary to check if we already traded in the current candle
      if (OrderOpenTime() > LastBarTraded || LastBarTraded == 0)
         LastBarTraded = OrderOpenTime();
   }
   return true;
}

//********************************************************************************************************

//-DUTO SPECIFIC EXPERT ADVISOR RUNNING FUNCTIONS-//

//********************************************************************************************************

// Initialize 
void InitializeEASettingsComments()
{
   SettingsComments = "==================\n";
   SettingsComments = SettingsComments + "Duto Settings\n";

   string str = "";

   switch (UpperTimeFrame)
   {
     case 0: 
      str = "1 HOUR"; 
      break; 

      case 10: 
      str = "15 MINUTE"; 
      break; 

      case 20: 
      str = "5 MINUTE"; 
      break; 
   }

   SettingsComments = SettingsComments + "Upper Timeframe : " + str + "\n";
   SettingsComments = SettingsComments + "S Trade Ratio Limit : " + BarColorCountThreshold + "\n";
   SettingsComments = SettingsComments + "Bar Count Limit : " + BarCountThreshold + "\n";
   SettingsComments = SettingsComments + "Lookback Count : " + LookBackCount + "\n";

   switch (TradeExitPlot)
   {
     case 6: 
      str = "MACD"; 
      break; 
      case 7: 
      str = "PLOT 2"; 
      break; 
   }

   SettingsComments = SettingsComments + "Exit Plot : " + str + "\n";
   SettingsComments = SettingsComments + "Allow Strat Dark : " + AllowStrat2Dark + "\n";

   if (UseTradingHours)
   {
      SettingsComments = SettingsComments + "Valid Trading Hours : " + TradingHourStart + "-" +  + TradingHourEnd + "\n";
   }
   else
   {
      SettingsComments = SettingsComments + "Valid Trading Hours : ALL" + "\n";
   }

   Comment(SettingsComments);  
}

void InitializeEACandleComments()
{
   CandleComments = "==================\n";
   CandleComments = CandleComments + "Duto Candle Data\n";
}

void InitializeEAPipComments()
{
   PipComments = "==================\n";
   PipComments = PipComments + "Duto Pip Data\n";
}

ENUM_SIGNAL_ENTRY ReturnSignalEntryToEvaluateEntry()
{  
   // Declaring the variables for the entry check
   SignalEntry = SIGNAL_ENTRY_NEUTRAL;

   //check for an entry
   //SignalEntry = DutoWind_2StrategyEntry();
   SignalEntry = SniperEntry();

   return SignalEntry;
}

ENUM_SIGNAL_EXIT ReturnSignalExitToEvaluateExit()

{
   // Declaring the variables for the exit check
   SignalExit = SIGNAL_EXIT_NEUTRAL;

   //check for an exit
   //SignalExit = DutoWind_2StrategyExit();
   SignalExit = SniperExit();

   return SignalExit;
}

void SetCandleZeroIndicatorData()
{
   //copy the index zero of the CombinedHistory to CombinedHistoryPrev
   //it is used to compare the last tick to the current tick
   //ArrayCopy(CombinedHistoryPrev, CombinedHistory, 0, 0, WHOLE_ARRAY);
   ArrayCopy(CombinedHistoryPrev, CombinedHistory, 0, 0, 1);

   //CombinedHistory[0][X] = NormalizeDouble(iCustom(Symbol(),60, duto_chart_indicators, X, 0), 5);

   //60

   //fast moving average
   CombinedHistory[0][2] = NormalizeDouble(iCustom(Symbol(),60, duto_chart_indicators, 0, 0), 5);
   //slow moving average
   CombinedHistory[0][3] = NormalizeDouble(iCustom(Symbol(),60, duto_chart_indicators, 1, 0), 5);
   //550 moving average
   CombinedHistory[0][4] = NormalizeDouble(iCustom(Symbol(),60, duto_chart_indicators, 4, 0), 5);
   
   //delta collapsed
   if (iCustom(Symbol(),60, duto_chart_indicators, 5, 0) == 2147483647) 
   {
      CombinedHistory[0][5] = -1;//delta collapsed negative
   }
   else {
      CombinedHistory[0][5] = 1;//delta collapsed positive
   }

   //macd histogram
   CombinedHistory[0][6] = iCustom(Symbol(),60, indicatorName, 0, 0);
   //plot 2
   CombinedHistory[0][7] = iCustom(Symbol(),60, indicatorName, 1, 0);
   //plot 3
   CombinedHistory[0][8] = iCustom(Symbol(),60, indicatorName, 2, 0);
   //plot 4
   CombinedHistory[0][9] = iCustom(Symbol(),60, indicatorName, 3, 0);
   //sniper
   //CombinedHistory[0][40] = iCustom(Symbol(),60, duto_sniper, 0, 0);
   CombinedHistory[0][42] = iCustom(Symbol(),60, SniperBlue, 0, 0);
   CombinedHistory[0][43] = iCustom(Symbol(),60, SniperPink, 0, 0);
   CombinedHistory[0][44] = iCustom(Symbol(),60, SniperPurple, 0, 0);

   //15
   
   //fast moving average
   CombinedHistory[0][12] = NormalizeDouble(iCustom(Symbol(),15, duto_chart_indicators, 0, 0), 5);
   //slow moving average
   CombinedHistory[0][13] = NormalizeDouble(iCustom(Symbol(),15, duto_chart_indicators, 1, 0), 5);
   //550 moving average
   CombinedHistory[0][14] = NormalizeDouble(iCustom(Symbol(),15, duto_chart_indicators, 4, 0), 5);
   
   //delta collapsed
   if (iCustom(Symbol(),15, duto_chart_indicators, 5, 0) == 2147483647) 
   {
      CombinedHistory[0][15] = -1;//delta collapsed negative
   }
   else {
      CombinedHistory[0][15] = 1;//delta collapsed positive
   }

   //macd histogram
   CombinedHistory[0][16] = iCustom(Symbol(),15, indicatorName, 0, 0);
   //plot 2
   CombinedHistory[0][17] = iCustom(Symbol(),15, indicatorName, 1, 0);
   //plot 3
   CombinedHistory[0][18] = iCustom(Symbol(),15, indicatorName, 2, 0);
   //plot 4
   CombinedHistory[0][19] = iCustom(Symbol(),15, indicatorName, 3, 0);
   //sniper
   //CombinedHistory[0][41] = iCustom(Symbol(),15, duto_sniper, 0, 0);
   CombinedHistory[0][47] = iCustom(Symbol(),15, SniperBlue, 0, 0);
   CombinedHistory[0][48] = iCustom(Symbol(),15, SniperPink, 0, 0);
   CombinedHistory[0][49] = iCustom(Symbol(),15, SniperPurple, 0, 0);

   //5
   
   //fast moving average
   CombinedHistory[0][22] = NormalizeDouble(iCustom(Symbol(),5, duto_chart_indicators, 0, 0), 5);
   //slow moving average
   CombinedHistory[0][23] = NormalizeDouble(iCustom(Symbol(),5, duto_chart_indicators, 1, 0), 5);
   //550 moving average
   CombinedHistory[0][24] = NormalizeDouble(iCustom(Symbol(),5, duto_chart_indicators, 4, 0), 5);
   
   //delta collapsed
   if (iCustom(Symbol(),5, duto_chart_indicators, 5, 0) == 2147483647) 
   {
      CombinedHistory[0][25] = -1;//delta collapsed negative
   }
   else {
      CombinedHistory[0][25] = 1;//delta collapsed positive
   }

   //macd histogram
   CombinedHistory[0][26] = iCustom(Symbol(),5, indicatorName, 0, 0);
   //plot 2
   CombinedHistory[0][27] = iCustom(Symbol(),5, indicatorName, 1, 0);
   //plot 3
   CombinedHistory[0][28] = iCustom(Symbol(),5, indicatorName, 2, 0);
   //plot 4
   CombinedHistory[0][29] = iCustom(Symbol(),5, indicatorName, 3, 0);
   //sniper
   //CombinedHistory[0][42] = iCustom(Symbol(),5, duto_sniper, 0, 0);
   CombinedHistory[0][52] = iCustom(Symbol(),5, SniperBlue, 0, 0);
   CombinedHistory[0][53] = iCustom(Symbol(),5, SniperPink, 0, 0);
   CombinedHistory[0][54] = iCustom(Symbol(),5, SniperPurple, 0, 0);

   //1
   
   //fast moving average
   CombinedHistory[0][32] = NormalizeDouble(iCustom(Symbol(),1, duto_chart_indicators, 0, 0), 5);
   //slow moving average
   CombinedHistory[0][33] = NormalizeDouble(iCustom(Symbol(),1, duto_chart_indicators, 1, 0), 5);
   //550 moving average
   CombinedHistory[0][34] = NormalizeDouble(iCustom(Symbol(),1, duto_chart_indicators, 4, 0), 5);
   
   //delta collapsed
   if (iCustom(Symbol(),1, duto_chart_indicators, 1, 0) == 2147483647) 
   {
      CombinedHistory[0][35] = -1;//delta collapsed negative
   }
   else {
      CombinedHistory[0][35] = 1;//delta collapsed positive
   }

   //macd histogram
   CombinedHistory[0][36] = iCustom(Symbol(),1, indicatorName, 0, 0);
   //plot 2
   CombinedHistory[0][37] = iCustom(Symbol(),1, indicatorName, 1, 0);
   //plot 3
   CombinedHistory[0][38] = iCustom(Symbol(),1, indicatorName, 2, 0);
   //plot 4
   CombinedHistory[0][39] = iCustom(Symbol(),1, indicatorName, 3, 0);
   //sniper
   //CombinedHistory[0][42] = iCustom(Symbol(),1, duto_sniper, 0, 0);
   CombinedHistory[0][57] = iCustom(Symbol(),1, SniperBlue, 0, 0);
   CombinedHistory[0][58] = iCustom(Symbol(),1, SniperPink, 0, 0);
   CombinedHistory[0][59] = iCustom(Symbol(),1, SniperPurple, 0, 0);

   /* PipComments = PipComments + "M5 MACD Candle 0 Prev: " + CombinedHistoryPrev[0][UpperTimeFrame + 10 + 6] + "\n";
   PipComments = PipComments + "M5 MACD Candle 0 Curr: " + CombinedHistory[0][UpperTimeFrame + 10 + 6] + "\n";
   PipComments = PipComments + "MACD > 0: " + (CombinedHistory[0][UpperTimeFrame + 10 + 6] > 0) + "\n"; */

   /* PipComments = PipComments + "Sniper Candle 2 M5: " + CombinedHistory[2][42] + "\n";
   PipComments = PipComments + "Sniper Candle 1 M1: " + CombinedHistory[1][43] + "\n";
   PipComments = PipComments + "Sniper Candle 0 M5: " + CombinedHistory[0][42] + "\n";

   if (CombinedHistory[1][43] > CombinedHistory[2][42])
   {
      PipComments = PipComments + "Sniper Creepin Up \n";   
   }
   if (CombinedHistory[1][43] < CombinedHistory[2][42])
   {
      PipComments = PipComments + "Sniper Creepin Down \n";   
   } */
}

void LogIndicatorData()
{
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

   ArrayResize(FastMAHistoryBuffer, 1000 + 1);
   ArrayResize(SlowMAHistoryBuffer, 1000 + 1);
   ArrayResize(FiveFiftyMAHistoryBuffer, 1000 + 1);
   ArrayResize(DeltaCollapsedPosHistoryBuffer, 1000 + 1);
   ArrayResize(DeltaCollapsedNegHistoryBuffer, 1000 + 1);

   ArrayResize(MacdHistoryBuffer, 1000 + 1);
   ArrayResize(MacdPlot2HistoryBuffer, 1000 + 1);
   ArrayResize(MacdPlot3HistoryBuffer, 1000 + 1);
   ArrayResize(MacdPlot4HistoryBuffer, 1000 + 1);

   ArrayResize(SniperHistoryBuffer, 1000 + 1);

   ArrayResize(CombinedHistory, 1000 + 1);

   for (int i = 0; i <= 1000; i++)
      {
         //60 build a line of data
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

         //SniperHistoryBuffer[i] = iCustom(Symbol(),60, duto_sniper, 0, i);
         //CombinedHistory[i][40] = SniperHistoryBuffer[i];//sniper
         CombinedHistory[i][42] = iCustom(Symbol(),60, SniperBlue, 0, i);//sniper
         CombinedHistory[i][43] = iCustom(Symbol(),60, SniperPink, 0, i);//sniper
         CombinedHistory[i][44] = iCustom(Symbol(),60, SniperPurple, 0, i);//sniper
         
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

         //15 build a line of data
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

         //SniperHistoryBuffer[i] = iCustom(Symbol(),15, duto_sniper, 0, i);
         //CombinedHistory[i][41] = SniperHistoryBuffer[i];//sniper
         CombinedHistory[i][47] = iCustom(Symbol(),15, SniperBlue, 0, i);//sniper
         CombinedHistory[i][48] = iCustom(Symbol(),15, SniperPink, 0, i);//sniper
         CombinedHistory[i][49] = iCustom(Symbol(),15, SniperPurple, 0, i);//sniper
         
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

         //5 build a line of data
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

         //SniperHistoryBuffer[i] = iCustom(Symbol(),5, duto_sniper, 0, i);
         //CombinedHistory[i][42] = SniperHistoryBuffer[i];//sniper
         CombinedHistory[i][52] = iCustom(Symbol(),5, SniperBlue, 0, i);//sniper
         CombinedHistory[i][53] = iCustom(Symbol(),5, SniperPink, 0, i);//sniper
         CombinedHistory[i][54] = iCustom(Symbol(),5, SniperPurple, 0, i);//sniper
         
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

         //1 build a line of data
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

         //SniperHistoryBuffer[i] = iCustom(Symbol(),1, duto_sniper, 0, i);
         //CombinedHistory[i][43] = SniperHistoryBuffer[i];//sniper
         CombinedHistory[i][57] = iCustom(Symbol(),1, SniperBlue, 0, i);//sniper
         CombinedHistory[i][58] = iCustom(Symbol(),1, SniperPink, 0, i);//sniper
         CombinedHistory[i][59] = iCustom(Symbol(),1, SniperPurple, 0, i);//sniper
         
         
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

         //sniper data

         + "," + i
         + "," + iTime(Symbol(), 60, i) 
         + "," + CombinedHistory[i][42]
         + "," + CombinedHistory[i][43]
         + "," + CombinedHistory[i][44]

         + "," + i
         + "," + iTime(Symbol(), 15, i) 
         + "," + CombinedHistory[i][47]
         + "," + CombinedHistory[i][48]
         + "," + CombinedHistory[i][49]

         + "," + i
         + "," + iTime(Symbol(), 5, i) 
         + "," + CombinedHistory[i][52]
         + "," + CombinedHistory[i][53]
         + "," + CombinedHistory[i][54]

         + "," + i
         + "," + iTime(Symbol(), 1, i) 
         + "," + CombinedHistory[i][57]
         + "," + CombinedHistory[i][58]
         + "," + CombinedHistory[i][59]

         /* //recent highest and recent lowest data
         + "," + CombinedHistory[i][44]
         + "," + CombinedHistory[i][45]
         + "," + CombinedHistory[i][46]
         + "," + CombinedHistory[i][47]
         + "," + CombinedHistory[i][48]
         + "," + CombinedHistory[i][49]
         + "," + CombinedHistory[i][50]
         + "," + CombinedHistory[i][51] */

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

void EvaluateSniper()
{
   int sniperIndex;
   string str;

   switch (UpperTimeFrame)
   {
      case 0: 
      //sniperIndex = 0;
      sniperIndex = 40;  
      break; 

      case 10: 
      //sniperIndex = 1;
      sniperIndex = 45;  
      break; 

      case 20: 
      //sniperIndex = 2; 
      sniperIndex = 50; 
      break;  
   }

   //blue sniper high, pink sniper low
   if (CombinedHistory[1][(sniperIndex + 2)] >= 99
      && CombinedHistory[1][(sniperIndex + 3)] <= 1)
   {
      str = "HIGH";
      SniperCockedHigh = true;
      SniperCockedLow = false;
      SniperCockedNeutral = false;

      ObjectCreate("objSniperObject_" + SniperObjectRunning, OBJ_TREND, 0, Time[0], 0, Time[0], 50000, 0, 0);
      ObjectSet("objSniperObject_" + SniperObjectRunning, OBJPROP_RAY , 0);
      ObjectSet("objSniperObject_" + SniperObjectRunning, OBJPROP_COLOR, clrDarkOliveGreen);
      ObjectSet("objSniperObject_" + SniperObjectRunning, OBJPROP_STYLE, STYLE_DOT);
      SniperObjectRunning++; 
   }
   else
   if (CombinedHistory[1][(sniperIndex + 2)] <= 1
      && CombinedHistory[1][(sniperIndex + 3)] >= 99)
   {
      str = "LOW";
      SniperCockedHigh = false;
      SniperCockedLow = true;
      SniperCockedNeutral = false; 

      ObjectCreate("objSniperObject_" + SniperObjectRunning, OBJ_TREND, 0, Time[0], 0, Time[0], 50000, 0, 0);
      ObjectSet("objSniperObject_" + SniperObjectRunning, OBJPROP_RAY , 0);
      ObjectSet("objSniperObject_" + SniperObjectRunning, OBJPROP_COLOR, clrLightCoral);
      ObjectSet("objSniperObject_" + SniperObjectRunning, OBJPROP_STYLE, STYLE_DOT);
      SniperObjectRunning++;    
   }
   else
   {
      SniperCockedHigh = false;
      SniperCockedLow = false;
      SniperCockedNeutral = true;
      str = "NEUTRAL";
   }
      
   CandleComments = CandleComments + "Sniper Blue Upper Tframe : " + CombinedHistory[1][(sniperIndex + 2)] + "\n";
   CandleComments = CandleComments + "Sniper Pink Upper Tframe : " + CombinedHistory[1][(sniperIndex + 3)] + "\n";
   
   CandleComments = CandleComments + "Sniper Cocked : " + str + "\n";
   //CandleComments = CandleComments + "SniperCockedHigh  : " + SniperCockedHigh + "\n";
   //CandleComments = CandleComments + "SniperCockedLow  : " + SniperCockedLow  + "\n";
   //CandleComments = CandleComments + "SniperCockedNeutral  : " + SniperCockedNeutral  + "\n";

   
}

double BarColorCount (int Idx, string Command){


   int count = 1;
   float barSum = 0.0;

   if (Command == "NEGATIVE" && CombinedHistory[count + 1][Idx] < 0 )
   {
      do 
     { 
      barSum = barSum + CombinedHistory[count + 1][Idx];
      count++; // without this operator an infinite loop will appear! 
     } 
      while(CombinedHistory[count + 1][Idx] < 0);

      Print("Bar sum absolute value: " + MathAbs(barSum));
      Print("Count: " + count);
      Print("Bar sum/BarColorCount: " + NormalizeDouble((MathAbs(barSum)/count) ,6));

      //if(count <= 20)
      if(count <= BarCountThreshold)
      {
         return MathAbs(barSum)/count;
      }
      else
      {
         Print("Rejected for count too high: " + count);
      } 
   }
   else
   if (Command == "POSITIVE" && CombinedHistory[count + 1][Idx] > 0)
   {
      do 
     { 
      barSum = barSum + CombinedHistory[count + 1][Idx];
      count++; // without this operator an infinite loop will appear! 
     } 
      while(CombinedHistory[count + 1][Idx] > 0);

      Print("Bar sum absolute value: " + MathAbs(barSum));
      Print("Count: " + count);
      Print("Bar sum/BarColorCount: " + NormalizeDouble((MathAbs(barSum)/count) ,6));

      //if(count <= 20)
      if(count <= BarCountThreshold)
      {
         return MathAbs(barSum)/count;
      } 
      else
      {
         Print("Rejected for count too high: " + count);
      }     
   }

   /* Print("Bar sum absolute value: " + MathAbs(barSum));
   Print("Returned BarColorCount: " + count);
   Print("Bar sum/BarColorCount: " + NormalizeDouble((MathAbs(barSum)/count) ,6)); */

   return 99.99;
   //return MathAbs(barSum)/count;
}

double GetLastHighestLowest(string command, int timeframe, int timeseries, int count, int start)
{
   double result;
   int returnedCandle;

  if (command == "HIGHEST")
   {
      returnedCandle = iHighest(Symbol(), Period(), MODE_HIGH, count, start);


      ObjectDelete("objLastHighest");
      ObjectCreate("objLastHighest", OBJ_HLINE, 0, Time[0], High[returnedCandle]);
      ObjectSet("objLastHighest", OBJPROP_COLOR,clrSeaGreen);
      ObjectSet("objLastHighest", OBJPROP_STYLE, STYLE_DASHDOTDOT);

      /* CandleComments = CandleComments + 
      "Last Highest: " + High[returnedCandle] + " at candle " + returnedCandle + "\n"; */

      result = High[returnedCandle];
   }
  else
   if (command == "LOWEST")
   {
      returnedCandle = iLowest(Symbol(), Period(), MODE_LOW, count, start);
      ObjectDelete("objLastLowest");
      ObjectCreate("objLastLowest", OBJ_HLINE, 0, Time[0], Low[returnedCandle]);
      ObjectSet("objLastLowest", OBJPROP_COLOR, clrFireBrick);
      ObjectSet("objLastLowest", OBJPROP_STYLE, STYLE_DASHDOTDOT);

      /* CandleComments = CandleComments + 
      "Last Lowest: " + Low[returnedCandle] + " at candle " + returnedCandle + "\n"; */

      result = Low[returnedCandle];
   }
  else
   {
      result == 99.99;
   }

   return result;
}

int CandleColorHowLong(int Idx, string command, int CndleStart)
{
   int count = 0;

   //if (command == "BR_GREEN" && (CombinedHistory[CndleStart][Idx] > CombinedHistory[CndleStart + 1][Idx]))
   //if (command == "BR_GREEN")
   if (command == "BR_GREEN" && (CombinedHistory[CndleStart][Idx] > CombinedHistory[CndleStart + 1][Idx])
      && (CombinedHistory[CndleStart][Idx] > 0) && (CombinedHistory[CndleStart + 1][Idx] > 0))
   {
      do
      { 
         count++;
      } 
      while(
         CombinedHistory[CndleStart + count][Idx] > CombinedHistory[CndleStart + count + 1][Idx]
         && CombinedHistory[CndleStart + count][Idx] > 0
         && CombinedHistory[CndleStart + count + 1][Idx] > 0

         /* CombinedHistory[CndleStart + count + 1][Idx] > CombinedHistory[CndleStart + count + 2][Idx]
         && CombinedHistory[CndleStart + count + 1][Idx] > 0
         && CombinedHistory[CndleStart + count + 2][Idx] > 0 */
         );

         //Print("BR_GREEN Count: " + count);
   }

   //if (command == "DK_GREEN" && (CombinedHistory[CndleStart][Idx] < CombinedHistory[CndleStart + 1][Idx]))
   //if (command == "DK_GREEN")
   if (command == "DK_GREEN" && (CombinedHistory[CndleStart][Idx] < CombinedHistory[CndleStart + 1][Idx])
      && (CombinedHistory[CndleStart][Idx] > 0) && (CombinedHistory[CndleStart + 1][Idx] > 0))
   {
      do
      { 
         count++;
      } 
      while(
         CombinedHistory[CndleStart + count][Idx] < CombinedHistory[CndleStart + count + 1][Idx]
         && CombinedHistory[CndleStart + count][Idx] > 0
         && CombinedHistory[CndleStart + count + 1][Idx] > 0

         /* CombinedHistory[CndleStart + count + 1][Idx] < CombinedHistory[CndleStart + count + 2][Idx]
         && CombinedHistory[CndleStart + count + 1][Idx] > 0
         && CombinedHistory[CndleStart + count + 2][Idx] > 0 */
         );

         //Print("DK_GREEN Count: " + count);
   }
  
   //if (command == "BR_RED" && (CombinedHistory[CndleStart][Idx] < CombinedHistory[CndleStart + 1][Idx]))
   //if (command == "BR_RED")
   if (command == "BR_RED" && (CombinedHistory[CndleStart][Idx] < CombinedHistory[CndleStart + 1][Idx])
      && (CombinedHistory[CndleStart][Idx] < 0) && (CombinedHistory[CndleStart + 1][Idx] < 0))
   {
      do
      { 
         count++;
      } 
      while(
         CombinedHistory[CndleStart + count][Idx] < CombinedHistory[CndleStart + count + 1][Idx]
         && CombinedHistory[CndleStart + count][Idx] < 0
         && CombinedHistory[CndleStart + count + 1][Idx] < 0

         /* CombinedHistory[CndleStart + count + 1][Idx] < CombinedHistory[CndleStart + count + 2][Idx]
         && CombinedHistory[CndleStart + count + 1][Idx] < 0
         && CombinedHistory[CndleStart + count + 2][Idx] < 0 */
         );

         //Print("BR_RED Count: " + count);
   }

   //if (command == "DK_RED" && (CombinedHistory[CndleStart][Idx] > CombinedHistory[CndleStart + 1][Idx]))
   //if (command == "DK_RED")
   if (command == "DK_RED" && (CombinedHistory[CndleStart][Idx] > CombinedHistory[CndleStart + 1][Idx])
      && (CombinedHistory[CndleStart][Idx] < 0) && (CombinedHistory[CndleStart + 1][Idx] < 0))

   {
      do
      { 
         count++;
      } 
      while(
         CombinedHistory[CndleStart + count][Idx] > CombinedHistory[CndleStart + count + 1][Idx]
         && CombinedHistory[CndleStart + count][Idx] < 0
         && CombinedHistory[CndleStart + count + 1][Idx] < 0
         
         /* CombinedHistory[CndleStart + count + 1][Idx] > CombinedHistory[CndleStart + count + 2][Idx]
         && CombinedHistory[CndleStart + count + 1][Idx] < 0
         && CombinedHistory[CndleStart + count + 2][Idx] < 0 */
         );

         //Print("DK_RED Count: " + count);
   }

   if (count > 0)
      //if candles were found then add 1 to the count so the last candle that
      //didn't match the conditions is included
      count = count + 1;

   return count;
}

bool EntryConditionsOk (string command, int CndleStart)
{
   bool result = false;

   if (command == "BUY"
         //ask less than the FMA
         //&& Ask < CombinedHistory[0][UpperTimeFrame + 10 + 2]
         //delta c positive
         //&& (CombinedHistory[CndleStart][UpperTimeFrame + 10 + 5] == 1)


         //MACD is at least some limit
         //&& (CombinedHistory[0][UpperTimeFrame + 10 + 6] > TradePendingMacdSP)

         //MACD
         && CombinedHistory[CndleStart][UpperTimeFrame + 10 + 6] >  CombinedHistory[CndleStart + 1][UpperTimeFrame + 10 + 6]
         && CombinedHistory[CndleStart][UpperTimeFrame + 10 + 6] > 0 && CombinedHistory[CndleStart + 1][UpperTimeFrame + 10 + 6] > 0
         //plot 2 is greater than 0 or dark red for some candle length
         && 
         (CombinedHistory[CndleStart][(UpperTimeFrame + 10 + 7)] > 0
         || (AllowStrat2Dark && CandleColorHowLong(UpperTimeFrame + 10 + 7, "DK_RED", 1) >= 1)
         )
         //plot 3 is greater than 0 or dark red for some candle length
         && 
         (CombinedHistory[CndleStart][(UpperTimeFrame + 8)] > 0
         || (AllowStrat2Dark && CandleColorHowLong(UpperTimeFrame + 10 + 8, "DK_RED", 1) >= 1)
         ) 
         //plot 4 is greater than 0 or dark red for some candle length
         && 
         (CombinedHistory[CndleStart][(UpperTimeFrame + 9)] > 0
         || (AllowStrat2Dark && CandleColorHowLong(UpperTimeFrame + 10 + 9, "DK_RED", 1) >= 1)
         ) 
      )    
   {
      result = true;
   }

   if (command == "SELL"
         //ask less than the FMA
         //&& Bid > CombinedHistory[0][UpperTimeFrame + 10 + 2]
         //delta c negative
         //&& (CombinedHistory[CndleStart][UpperTimeFrame + 10 + 5] == -1)
         //MACD is at least some limit
         //&& (CombinedHistory[0][UpperTimeFrame + 10 + 6] < TradePendingMacdSP)

         //MACD
         && CombinedHistory[CndleStart][UpperTimeFrame + 10 + 6] <  CombinedHistory[CndleStart + 1][UpperTimeFrame + 10 + 6]
         && CombinedHistory[CndleStart][UpperTimeFrame + 10 + 6] < 0 && CombinedHistory[CndleStart + 1][UpperTimeFrame + 10 + 6] < 0
         //plot 2 is greater than 0 or dark red for some candle length
         && 
         (CombinedHistory[CndleStart][(UpperTimeFrame + 10 + 7)] < 0
         || (AllowStrat2Dark && CandleColorHowLong(UpperTimeFrame + 10 + 7, "DK_GREEN", 1) >= 1)
         )
         //plot 3 is greater than 0 or dark red for some candle length
         && 
         (CombinedHistory[CndleStart][(UpperTimeFrame + 8)] < 0
         || (AllowStrat2Dark && CandleColorHowLong(UpperTimeFrame + 10 + 8, "DK_GREEN", 1) >= 1)
         ) 
         //plot 4 is greater than 0 or dark red for some candle length
         && 
         (CombinedHistory[CndleStart][(UpperTimeFrame + 9)] < 0
         || (AllowStrat2Dark && CandleColorHowLong(UpperTimeFrame + 10 + 9, "DK_GREEN", 1) >= 1)
         ) 
      )    
   {
      result = true;
   }

   return result;
}

void WriteTextToRight()
{
   ObjectDelete("objTest1");
   ObjectDelete("objTest2");

   string str="TEST BITCHES.";

   ObjectCreate("objTest1", OBJ_LABEL, 0, 0, 0);
   ObjectSetText("objTest1",str, 8,"Arial", Yellow); // 
   ObjectSet("objTest1", OBJPROP_CORNER, 1);
   ObjectSet("objTest1", OBJPROP_XDISTANCE, 1);
   ObjectSet("objTest1", OBJPROP_YDISTANCE, 15);

   ObjectCreate("objTest2", OBJ_LABEL, 0, 0, 0);
   ObjectSetText("objTest2",str, 8,"Arial", Yellow); // 
   ObjectSet("objTest2", OBJPROP_CORNER, 1);
   ObjectSet("objTest2", OBJPROP_XDISTANCE, 1);
   ObjectSet("objTest2", OBJPROP_YDISTANCE, 30);

}

void EvaluateSymmetry(int Idx, string command, int CndleStart)
{
   //change from bright red to dark red
   if (AskThePlotsColorChange(UpperTimeFrame + 10 + 6, 1, 1, "BUY_BR_RED_DK_RED") == "PLOT INCREASING BRIGHT RED TO DARK RED")
      {
         int numBrRdCandles, numDkGrCandles, numBrGrCandles, numDkRdCandles;

         if (command == "BUY_BR_RED_DK_RED")
         {
            numBrRdCandles = CandleColorHowLong(Idx, "BR_RED", CndleStart);
            numDkGrCandles = CandleColorHowLong(Idx, "DK_GREEN", numBrRdCandles + CndleStart) - 1; 
            numBrGrCandles = CandleColorHowLong(Idx, "BR_GREEN", numBrRdCandles + numDkGrCandles + CndleStart);
            numDkRdCandles = CandleColorHowLong(Idx, "DK_RED", numBrRdCandles + numDkGrCandles + numBrGrCandles + CndleStart) - 1;

            /* Print("numBrRdCandles: " + numBrRdCandles);
            Print("Last BrRd candle value: " + CombinedHistory[numBrRdCandles + 1][UpperTimeFrame + 10 + 6]);

            Print("numDkGrCandles: " + numDkGrCandles);
            Print("Last DkGr candle value: " + CombinedHistory[(numBrRdCandles + 1) + numDkGrCandles][UpperTimeFrame + 10 + 6]);

            Print("numBrGrCandles: " + numBrGrCandles);
            Print("Last BrGr candle value: " + CombinedHistory[(numBrRdCandles + 1) + numDkGrCandles + numBrGrCandles][UpperTimeFrame + 10 + 6]);

            Print("numDkRdCandles: " + numDkRdCandles);
            Print("Last DkRd candle value: " + CombinedHistory[(numBrRdCandles + 1) + numDkGrCandles + numBrGrCandles + numDkRdCandles][UpperTimeFrame + 10 + 6]); */

            if(
               (numBrRdCandles >= 3)
               && (numDkGrCandles >= 3)
               && (numBrGrCandles >=3)
               && (numDkRdCandles >= 3)
            )
            {
            /* Print("numBrRdCandles: " + numBrRdCandles);
            Print("Last BrRd candle value: " + CombinedHistory[numBrRdCandles + 1][UpperTimeFrame + 10 + 6]);
               
            Print("numDkGrCandles: " + numDkGrCandles);
            Print("Last DkGr candle value: " + CombinedHistory[(numBrRdCandles + 1) + numDkGrCandles][UpperTimeFrame + 10 + 6]);

            Print("numBrGrCandles: " + numBrGrCandles);
            Print("Last BrGr candle value: " + CombinedHistory[(numBrRdCandles + 1) + numDkGrCandles + numBrGrCandles][UpperTimeFrame + 10 + 6]);

            Print("numDkRdCandles: " + numDkRdCandles);
            Print("Last DkRd candle value: " + CombinedHistory[(numBrRdCandles + 1) + numDkGrCandles 
            + numBrGrCandles + numDkRdCandles][UpperTimeFrame + 10 + 6]); */

            //ObjectCreate("objSymmetryObject_" + SymmetryObjectRunning, OBJ_VLINE, 0, Time[0], 0);
            ObjectCreate("objSymmetryObject_" + SymmetryObjectRunning, OBJ_TREND, 0, Time[0], 0, Time[0], 50000, 0, 0);
            ObjectSet("objSymmetryObject_" + SymmetryObjectRunning, OBJPROP_RAY , 0);
            ObjectSet("objSymmetryObject_" + SymmetryObjectRunning, OBJPROP_COLOR,clrSeaGreen);
            ObjectSet("objSymmetryObject_" + SymmetryObjectRunning, OBJPROP_STYLE, STYLE_DASHDOTDOT);
            SymmetryObjectRunning++; 
            }
         }         
      }  
}

void EvaluateLastHighestLowest()
{
   //find the last highest and lowest
   LastHighest = GetLastHighestLowest("HIGHEST", 0, MODE_HIGH, LookBackCount, 1);
   LastLowest = GetLastHighestLowest("LOWEST", 0, MODE_LOW, LookBackCount, 1);

   CandleComments = CandleComments + 
   "Last Highest: " + LastHighest + "--Last Lowest: " + LastLowest + "\n";
}

string AskThePlotsColorChange(int Idx, int CndleStart, int CmbndHstryCandleLength, string OverallStrategy)
{
   string result = "";

   //STRATEGY LOGIC
 
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

   return result;
}

/* DrawDutoObject("objSymmetryObject", SymmetryObjectRunning, 
      OBJ_VLINE, clrSeaGreen, STYLE_DASHDOTDOT); */

/* void DrawDutoObject(string ObjPrefix, int ObjRunning, 
   ENUM_OBJECT ObjType, color ObjColor, int ObjStyle)
{
   ObjectCreate(ObjPrefix + "_" + ObjRunning, ObjType, 0, Time[0], 0);
   ObjectSet(ObjPrefix + "_" + ObjRunning, OBJPROP_COLOR, ObjColor);
   ObjectSet(ObjPrefix + "_" + ObjRunning, OBJPROP_STYLE, ObjStyle);
   ObjRunning++;
} */

void xstart(){
    Trend_Line(Time[10],Time[0],Open[10],Open[0],Gold,STYLE_SOLID);
}

void Trend_Line(
    datetime x1, datetime x2, double y1, 
    double y2, color lineColor, double style){
    //~~~~~~~~~~
    string label = "_Trend_Line_";
    ObjectDelete(label);
    ObjectCreate(label, OBJ_TREND, 0, x1, y1, x2, y2, 0, 0);
    ObjectSet(label, OBJPROP_RAY, 0);
    ObjectSet(label, OBJPROP_COLOR, lineColor);
    ObjectSet(label, OBJPROP_STYLE, style);
    //~~~~~~~~~~
}

//********************************************************************************************************

//BEGIN DUTO STRATEGY, ENTRY AND EXIT

//********************************************************************************************************

//execute the selected strategy
void DutoWind_SelectedStrategy()
{
   //DutoWind_2Strategy();
   SniperStrategy();
   CandleComments = CandleComments + "Current Strategy : " + CurrentStrategy + "\n";
}

void DutoWind_2Strategy()
{
   //BuySafetyTrade2Strategy = false;
   //SellSafetyTrade2Strategy = false;
   //NeutralSafetyTrade2Strategy = false;
   CurrentStrategy = "";

   //BUY 2 STRATEGY SAFETY TRADE
   if (
      (AskThePlots2Strategy((UpperTimeFrame + 6), 1, 1, "ST_BUY_2_STRATEGY") == "SAFETY TRADE BUY 2 STRATEGY") 
      )
   {
      SellStrategyActive = false;
      BuyStrategyActive = true;
      NeutralStrategyActive = false;

      SellSafetyTrade2Strategy = false;
      BuySafetyTrade2Strategy = true;
      NeutralSafetyTrade2Strategy = false;

      //close all sell trades
      CloseAll(OP_SELL);

      /* Print("SAFETY TRADE BUY 2 STRATEGY IN EFFECT. SellStrategyActive: " + SellStrategyActive + " BuyStrategyActive: " + BuyStrategyActive 
      + " NeutralStrategyActive: " + NeutralStrategyActive);
      Print("BuySafetyTrade2Strategy: " + BuySafetyTrade2Strategy); */     
   }

   //SELL 2 STRATEGY SAFETY TRADE
   if (
      (AskThePlots2Strategy((UpperTimeFrame + 6), 1, 1, "ST_SELL_2_STRATEGY") == "SAFETY TRADE SELL 2 STRATEGY") 
      )
   {
      SellStrategyActive = true;
      BuyStrategyActive = false;
      NeutralStrategyActive = false;

      SellSafetyTrade2Strategy = true;
      BuySafetyTrade2Strategy = false;
      NeutralSafetyTrade2Strategy = false;

      //close all sell trades
      CloseAll(OP_BUY);

      /* Print("SAFETY TRADE SELL 2 STRATEGY IN EFFECT. SellStrategyActive: " + SellStrategyActive + " BuyStrategyActive: " + BuyStrategyActive 
      + " NeutralStrategyActive: " + NeutralStrategyActive);
      Print("SellSafetyTrade2Strategy: " + SellSafetyTrade2Strategy);  */   
   }

   //NEUTRAL 2 STRATEGY SAFETY TRADE
   if (
      (AskThePlots2Strategy((UpperTimeFrame + 6), 1, 1, "ST_NEUTRAL_2_STRATEGY") == "SAFETY TRADE NEUTRAL 2 STRATEGY") 
      )
   {
      BuyTradesValid = false;
      SellTradesValid = false;
      
      SellStrategyActive = false;
      BuyStrategyActive = false;
      NeutralStrategyActive = true;

      SellSafetyTrade2Strategy = true;
      BuySafetyTrade2Strategy = false;
      NeutralSafetyTrade2Strategy = true;

      //close all sell trades
      CloseAll(OP_ALL);

      /* Print("SAFETY TRADE NEUTRAL 2 STRATEGY IN EFFECT. SellStrategyActive: " + SellStrategyActive + " BuyStrategyActive: " + BuyStrategyActive 
      + " NeutralStrategyActive: " + NeutralStrategyActive);
      Print("NeutralSafetyTrade2Strategy: " + NeutralSafetyTrade2Strategy); */     
   }
}

ENUM_SIGNAL_ENTRY DutoWind_2StrategyEntry()
{
   //ENTRY LOGIC

   //don't allow new trades to be made outside of the selected trading hours
   if (UseTradingHours && !IsOperatingHours)
   {
      //Print("DutoWind_2StrategyEntry: UseTradingHours && !IsOperatingHours");
      SignalEntry = SIGNAL_ENTRY_NEUTRAL;
      return SignalEntry; // If you are using trading hours and it's not a trading hour don't give an entry signal
   } 

   //BUY ENTRY //ACTIVE 
   if (
         (AskThePlots2StrategyEntry(UpperTimeFrame + 10 + 6, 1, 1, "BUY_ST_ENTRY") == "ENTER A SAFETY TRADE BUY")
         //(AskThePlots2StrategyEntry(UpperTimeFrame + 10 + 7, 1, 1, "BUY_ST_ENTRY") == "ENTER A SAFETY TRADE BUY")
         && BuyStrategyActive == true 
         && BuyTradeActive == false

         && BuySafetyTrade2Strategy == true
      )
   {
      //BuyTradesValid = true;
      BuyTradeActive = true;

      Print("ENTER A SAFETY TRADE BUY." +
      "SellTradeActive: " + SellTradeActive + 
      " BuyTradeActive: " + BuyTradeActive + 
      " BuySafetyTrade2Strategy: " + BuySafetyTrade2Strategy);

      EntryData[1][10] = Ask;
      SignalEntry = SIGNAL_ENTRY_BUY;
   }

   //SELL ENTRY //ACTIVE
  
   if (
         (AskThePlots2StrategyEntry(UpperTimeFrame + 10 + 6, 1, 1, "SELL_ST_ENTRY") == "ENTER A SAFETY TRADE SELL")
         //(AskThePlots2StrategyEntry(UpperTimeFrame + 10 + 7, 1, 1, "SELL_ST_ENTRY") == "ENTER A SAFETY TRADE SELL")
         && SellStrategyActive == true 
         && SellTradeActive == false

         && SellSafetyTrade2Strategy == true
      )
   {
      //SellTradesValid = true;
      SellTradeActive = true;

      Print("ENTER A SAFETY TRADE SELL." +
      "SellTradeActive: " + SellTradeActive + 
      " BuyTradeActive: " + BuyTradeActive + 
      " SellSafetyTrade2Strategy: " + SellSafetyTrade2Strategy);

      EntryData[0][10] = Bid;
      SignalEntry = SIGNAL_ENTRY_SELL;
   }

   //SignalEntry = SIGNAL_ENTRY_NEUTRAL;

   return SignalEntry;
}

ENUM_SIGNAL_EXIT DutoWind_2StrategyExit()
{ 
   //EXIT LOGIC

   //ACTIVE
   //BUY EXIT
   if (
      //AskThePlots2StrategyExit(37, 1, 1, "BUY_ST_EXIT") == "EXIT A SAFETY TRADE BUY"
      AskThePlots2StrategyExit(UpperTimeFrame + 10 + TradeExitPlot, 1, 1, "BUY_ST_EXIT") == "EXIT A SAFETY TRADE BUY"
      //AskThePlots2StrategyExit(UpperTimeFrame + 10 + 6, 1, 1, "BUY_ST_EXIT") == "EXIT A SAFETY TRADE BUY"
      && BuyStrategyActive == true 
      && BuyTradeActive == true

      && BuySafetyTrade2Strategy == true
      //&& Bid > EntryData[1][10] //current price is greater than the price it was entered at
      )
   {
      BuyTradeActive = false;
      //BuyBrRdDkRdStrategyActive = false;

      Print("Ask/EntryData[0][10] in BUY_ST_EXIT: " + Ask + "/" + EntryData[0][10]);
      Print("EXIT A SAFETY TRADE BUY. SellStrategyActive: " + SellStrategyActive + " BuyStrategyActive: " + BuyStrategyActive);
      
      SignalExit = SIGNAL_EXIT_BUY;
   }

   //ACTIVE
   //SELL EXIT
   if (
      //AskThePlots2StrategyExit(37, 1, 1, "SELL_ST_EXIT") == "EXIT A SAFETY TRADE SELL"
      AskThePlots2StrategyExit(UpperTimeFrame + 10 + TradeExitPlot, 1, 1, "SELL_ST_EXIT") == "EXIT A SAFETY TRADE SELL"
      //AskThePlots2StrategyExit(UpperTimeFrame + 10 + 6, 1, 1, "SELL_ST_EXIT") == "EXIT A SAFETY TRADE SELL"
      && SellStrategyActive == true 
      && SellTradeActive == true

      && SellSafetyTrade2Strategy == true
      //&& Bid > EntryData[1][10] //current price is greater than the price it was entered at
      )
   {
      SellTradeActive = false;
      //BuyBrRdDkRdStrategyActive = false;

      Print("Ask/EntryData[0][10] in SELL_ST_EXIT: " + Ask + "/" + EntryData[0][10]);
      Print("EXIT A SAFETY TRADE BUY. SellStrategyActive: " + SellStrategyActive + " BuyStrategyActive: " + BuyStrategyActive);
      
      SignalExit = SIGNAL_EXIT_SELL;
   }

   //SignalExit = SIGNAL_EXIT_NEUTRAL;

   return SignalExit;
}

string AskThePlots2Strategy(int Idx, int CndleStart, int CmbndHstryCandleLength, string OverallStrategy)
{
   string result = "";

   //SAFETY TRADE BUY 2 STRATEGY
   if (
      OverallStrategy == "ST_BUY_2_STRATEGY"

      //HIGHER TIME FRAME

      //plot 1 candle 1 is positive
      && 
      (
         CombinedHistory[CndleStart][(UpperTimeFrame + 6)] > 0
         || 
         (AllowStrat2Dark 
         && CandleColorHowLong(UpperTimeFrame + 6, "DK_RED", 1) >= 1)
      )
      //plot 1 candle 1 is positive
      //&& CombinedHistory[CndleStart][(UpperTimeFrame + 7)] > 0
      && 
      (
         CombinedHistory[CndleStart][(UpperTimeFrame + 7)] > 0
         || 
         (AllowStrat2Dark 
         && CandleColorHowLong(UpperTimeFrame + 7, "DK_RED", 1) >= 1)
      )
      //plot 1 candle 1 is positive
      //&& CombinedHistory[CndleStart][(UpperTimeFrame + 8)] > 0
      && 
      (
         CombinedHistory[CndleStart][(UpperTimeFrame + 8)] > 0
         || 
         (AllowStrat2Dark 
         && CandleColorHowLong(UpperTimeFrame + 8, "DK_RED", 1) >= 1)
      )
      //plot 1 candle 1 is positive
      //&& CombinedHistory[CndleStart][(UpperTimeFrame + 9)] > 0
      && 
      (
         CombinedHistory[CndleStart][(UpperTimeFrame + 9)] > 0
         || 
         (AllowStrat2Dark 
         && CandleColorHowLong(UpperTimeFrame + 9, "DK_RED", 1) >= 1)
      )

      //LOWER TIME FRAME
      
      /* //plot 1 candle 1 is positive
      && CombinedHistory[CndleStart][(UpperTimeFrame + 10 + 7)] > 0
      //plot 1 candle 1 is positive
      && CombinedHistory[CndleStart][(UpperTimeFrame + 10 + 8)] > 0
      //plot 1 candle 1 is positive
      && CombinedHistory[CndleStart][(UpperTimeFrame + 10 + 9)] > 0 */
      )
   {
      CurrentStrategy = OverallStrategy; 
      result = "SAFETY TRADE BUY 2 STRATEGY"; 
   }

   //SAFETY TRADE SELL 2 STRATEGY, ALL DARK RED OR BRIGHT RED
   if (
      OverallStrategy == "ST_SELL_2_STRATEGY"

      //HIGHER TIME FRAME

      //plot 1 candle 1 is positive
      //&& CombinedHistory[CndleStart][(UpperTimeFrame + 6)] < 0
      && 
      (
         CombinedHistory[CndleStart][(UpperTimeFrame + 6)] < 0
         || 
         (AllowStrat2Dark 
         && CandleColorHowLong(UpperTimeFrame + 6, "DK_GREEN", 1) >= 1)
      )
      //plot 1 candle 1 is positive
      //&& CombinedHistory[CndleStart][(UpperTimeFrame + 7)] < 0
      && 
      (
         CombinedHistory[CndleStart][(UpperTimeFrame + 7)] < 0
         || 
         (AllowStrat2Dark 
         && CandleColorHowLong(UpperTimeFrame + 7, "DK_GREEN", 1) >= 1)
      )
      //plot 1 candle 1 is positive
      //&& CombinedHistory[CndleStart][(UpperTimeFrame + 8)] < 0
      && 
      (
         CombinedHistory[CndleStart][(UpperTimeFrame + 8)] < 0
         || 
         (AllowStrat2Dark 
         && CandleColorHowLong(UpperTimeFrame + 8, "DK_GREEN", 1) >= 1)
      )
      //plot 1 candle 1 is positive
      //&& CombinedHistory[CndleStart][(UpperTimeFrame + 9)] < 0
      && 
      (
         CombinedHistory[CndleStart][(UpperTimeFrame + 9)] < 0
         || 
         (AllowStrat2Dark 
         && CandleColorHowLong(UpperTimeFrame + 9, "DK_GREEN", 1) >= 1)
      )

      //LOWER TIME FRAME

      /* //plot 1 candle 1 is positive
      && CombinedHistory[CndleStart][(UpperTimeFrame + 10 + 7)] < 0
      //plot 1 candle 1 is positive
      && CombinedHistory[CndleStart][(UpperTimeFrame + 10 +8)] < 0
      //plot 1 candle 1 is positive
      && CombinedHistory[CndleStart][(UpperTimeFrame + 10 + 9)] < 0 */
      )
   {
      CurrentStrategy = OverallStrategy; 
      result = "SAFETY TRADE SELL 2 STRATEGY";

      /* if (SellSafetyTrade2Strategy == false)
      {
         Print("SAFETY TRADE SELL 2 STRATEGY IN EFFECT. SellStrategyActive: " + SellStrategyActive + " BuyStrategyActive: " + BuyStrategyActive 
         + " NeutralStrategyActive: " + NeutralStrategyActive);
         Print("SellSafetyTrade2Strategy: " + SellSafetyTrade2Strategy); 
      }  */
   }

   //SAFETY TRADE NEUTRAL 2 STRATEGY, ALL DARK RED OR BRIGHT RED
   if (
      OverallStrategy == "ST_NEUTRAL_2_STRATEGY"

      && CurrentStrategy != "ST_BUY_2_STRATEGY"
      && CurrentStrategy != "ST_SELL_2_STRATEGY"
      )
   {
      CurrentStrategy = OverallStrategy; 
      //Print("ask the plots PLOT INCREASING DARK GREEN TO BRIGHT GREEN");
      result = "SAFETY TRADE NEUTRAL 2 STRATEGY"; 

      /* if (NeutralSafetyTrade2Strategy == false)
      {
         Print("SAFETY TRADE NEUTRAL 2 STRATEGY IN EFFECT. SellStrategyActive: " + SellStrategyActive + " BuyStrategyActive: " + BuyStrategyActive 
         + " NeutralStrategyActive: " + NeutralStrategyActive);
         Print("NeutralSafetyTrade2Strategy: " + NeutralSafetyTrade2Strategy);  
      }  */
   }

   return result;
}

string AskThePlots2StrategyEntry(int Idx, int CndleStart, int CmbndHstryCandleLength, string OverallStrategy)
{
   string result = "";

   //ENTRY LOGIC

   //ACTIVE
   //BUY ENTRY SAFETY TRADE
   if (
      BuyStrategyActive == true 
      && OverallStrategy == "BUY_ST_ENTRY"
      && BuySafetyTrade2Strategy == true

      //enter on macd
      && CombinedHistory[CndleStart][Idx] >  CombinedHistory[CndleStart + 1][Idx]
      && CombinedHistory[CndleStart][Idx] > 0 && CombinedHistory[CndleStart + 1][Idx] < 0

      /* //enter on plot 2
      && CombinedHistory[CndleStart][Idx] >  CombinedHistory[CndleStart + 1][Idx]
      && CombinedHistory[CndleStart + 1][Idx] < CombinedHistory[CndleStart + 2][Idx] */

      //plot 2 is increasing
      //&& CombinedHistory[CndleStart][Idx + 1] >  CombinedHistory[CndleStart + 1][Idx + 1]

      //this version calculates the ratio between the sum of the bars and the number of the bars
      //&& BarColorCount(Idx, "NEGATIVE") <= BarColorCountThreshold
      // SniperCockedHigh
      )
   { 
      Print("AskThePlots2StrategyEntry buy.");
      result = "ENTER A SAFETY TRADE BUY";
   }

   //ACTIVE
   //SELL ENTRY SAFETY TRADE
   if (
      SellStrategyActive == true 
      && OverallStrategy == "SELL_ST_ENTRY"
      && SellSafetyTrade2Strategy == true

      //enter on macd
      && CombinedHistory[CndleStart][Idx] <  CombinedHistory[CndleStart + 1][Idx]
      && CombinedHistory[CndleStart][Idx] < 0 && CombinedHistory[CndleStart + 1][Idx] > 0

      /* //enter on plot 2
      && CombinedHistory[CndleStart][Idx] <  CombinedHistory[CndleStart + 1][Idx]
      && CombinedHistory[CndleStart + 1][Idx] > CombinedHistory[CndleStart + 2][Idx] */

      //plot 2 is decreasing
      //&& CombinedHistory[CndleStart][Idx + 1] <  CombinedHistory[CndleStart + 1][Idx + 1]

      //this version calculates the ratio between the sum of the bars and the number of the bars
      //&& BarColorCount(Idx, "POSITIVE") <= BarColorCountThreshold
      // SniperCockedLow
      )
   {  
      result = "ENTER A SAFETY TRADE SELL";
   }

   return result;
}

string AskThePlots2StrategyExit(int Idx, int CndleStart, int CmbndHstryCandleLength, string OverallStrategy)
{
   string result = "";

   //EXIT LOGIC

   //BUY EXIT SAFETY TRADE
   if (
      OverallStrategy == "BUY_ST_EXIT" 

      && 
         (  //typical take profit exit
            (CombinedHistory[CndleStart][Idx] < CombinedHistory[CndleStart + 1][Idx]
            && CombinedHistory[CndleStart + 1][Idx] > CombinedHistory[CndleStart + 2][Idx]

            //commented out the bid/ask restriction so I can exit early
            //if the macd goes bad
            && Bid > EntryData[1][10]
            && CombinedHistory[CndleStart][Idx] > 0)
         ||
            //
            (CombinedHistory[CndleStart][UpperTimeFrame + 10 + 6] 
            < CombinedHistory[CndleStart + 1][UpperTimeFrame + 10 + 6])
         ||
            //exit if the macd turns to avoid losses
            (CombinedHistory[0][UpperTimeFrame + 10 + 6] < 0)
         )
      )
   {
      //Print("Bid: " + Bid + " > EntryData[1][10]: " + EntryData[1][10]);
      result = "EXIT A SAFETY TRADE BUY";
   }

   //SELL EXIT SAFETY TRADE
   if (
      OverallStrategy == "SELL_ST_EXIT" 

      && 
         (  //typical take profit exit
            (CombinedHistory[CndleStart][Idx] > CombinedHistory[CndleStart + 1][Idx] 
            //commented out the bid/ask restriction so I can exit early
            //if the macd goes bad
            && Ask < EntryData[0][10]
            && CombinedHistory[CndleStart][Idx] < 0)
         ||
            //
            (CombinedHistory[CndleStart][UpperTimeFrame + 10 + 6] 
            > CombinedHistory[CndleStart + 1][UpperTimeFrame + 10 + 6])
         ||
            //exit if the macd turns to avoid losses
            (CombinedHistory[0][UpperTimeFrame + 10 + 6] > 0)
         )
      )
   {
      //Print("Bid: " + Bid + " > EntryData[1][10]: " + EntryData[1][10]);
      result = "EXIT A SAFETY TRADE SELL";
   }

   return result;
}

void SniperStrategy()
{
   CurrentStrategy = "";

   //BUY SNIPER
   if (SniperCockedHigh == true
      && SniperCockedLow == false
      && SniperCockedNeutral == false)
   {
      SellStrategyActive = false;
      BuyStrategyActive = true;
      NeutralStrategyActive = false;

      //SellSafetyTrade2Strategy = false;
      //BuySafetyTrade2Strategy = true;
      //NeutralSafetyTrade2Strategy = false;

      CurrentStrategy ="Sniper Buy";

      //close all sell trades
      //CloseAll(OP_SELL);

      Print("SNIPER BUY STRATEGY IN EFFECT. SellStrategyActive: " + SellStrategyActive + " BuyStrategyActive: " + BuyStrategyActive 
      + " NeutralStrategyActive: " + NeutralStrategyActive);
      //Print("BuySafetyTrade2Strategy: " + BuySafetyTrade2Strategy);     
   }

   //SELL SNIPER
   if (SniperCockedHigh == false
      && SniperCockedLow == true
      && SniperCockedNeutral == false)
   {
      SellStrategyActive = true;
      BuyStrategyActive = false;
      NeutralStrategyActive = false;

      //SellSafetyTrade2Strategy = true;
      //BuySafetyTrade2Strategy = false;
      //NeutralSafetyTrade2Strategy = false;

      CurrentStrategy ="Sniper Sell";

      //close all buy trades
      //CloseAll(OP_BUY);

      Print("SNIPER SELL STRATEGY IN EFFECT. SellStrategyActive: " + SellStrategyActive + " BuyStrategyActive: " + BuyStrategyActive 
      + " NeutralStrategyActive: " + NeutralStrategyActive);
      //Print("SellSafetyTrade2Strategy: " + SellSafetyTrade2Strategy);    
   }

   //NEUTRAL SNIPER
   if (SniperCockedHigh == false
      && SniperCockedLow == false
      && SniperCockedNeutral == true 
      )
   {
      BuyTradesValid = false;
      SellTradesValid = false;
      
      SellStrategyActive = false;
      BuyStrategyActive = false;
      NeutralStrategyActive = true;

      //SellSafetyTrade2Strategy = true;
      //BuySafetyTrade2Strategy = false;
      //NeutralSafetyTrade2Strategy = true;

      CurrentStrategy ="Sniper Neutral";

      //close all trades
      //CloseAll(OP_ALL);

      /* Print("SNIPER NEUTRAL STRATEGY IN EFFECT. SellStrategyActive: " + SellStrategyActive + " BuyStrategyActive: " + BuyStrategyActive 
      + " NeutralStrategyActive: " + NeutralStrategyActive); */
      //Print("NeutralSafetyTrade2Strategy: " + NeutralSafetyTrade2Strategy);   
   }
}

ENUM_SIGNAL_ENTRY SniperEntry()
{
   //ENTRY LOGIC

   //don't allow new trades to be made outside of the selected trading hours
   if (UseTradingHours && !IsOperatingHours)
   {
      //Print("DutoWind_2StrategyEntry: UseTradingHours && !IsOperatingHours");
      SignalEntry = SIGNAL_ENTRY_NEUTRAL;
      return SignalEntry; // If you are using trading hours and it's not a trading hour don't give an entry signal
   } 

   //BUY ENTRY //ACTIVE 
   if (
         //(AskThePlotsSniperEntry(53, 1, 1, "BUY_SNIPER_ENTRY") == "ENTER A SNIPER TRADE BUY")
         (AskThePlotsSniperEntry(58, 1, 1, "BUY_SNIPER_ENTRY") == "ENTER A SNIPER TRADE BUY")
         && SniperCockedHigh == true
         && BuyStrategyActive == true 
         && BuyTradeActive == false

         //&& BuySafetyTrade2Strategy == true
      )
   {
      //BuyTradesValid = true;
      BuyTradeActive = true;

      Print("ENTER A SNIPER TRADE BUY." +
      "SellTradeActive: " + SellTradeActive + 
      " BuyTradeActive: " + BuyTradeActive + 
      " BuySafetyTrade2Strategy: " + BuySafetyTrade2Strategy);

      EntryData[1][10] = Ask;
      SignalEntry = SIGNAL_ENTRY_BUY;
   }

   //SELL ENTRY //ACTIVE
  
   if (
         //(AskThePlotsSniperEntry(53, 1, 1, "SELL_SNIPER_ENTRY") == "ENTER A SNIPER TRADE SELL")
         (AskThePlotsSniperEntry(58, 1, 1, "SELL_SNIPER_ENTRY") == "ENTER A SNIPER TRADE SELL")
         && SniperCockedLow == true
         && SellStrategyActive == true 
         && SellTradeActive == false

         //&& SellSafetyTrade2Strategy == true
      )
   {
      //SellTradesValid = true;
      SellTradeActive = true;

      Print("ENTER A SNIPER TRADE SELL." +
      "SellTradeActive: " + SellTradeActive + 
      " BuyTradeActive: " + BuyTradeActive + 
      " SellSafetyTrade2Strategy: " + SellSafetyTrade2Strategy);

      EntryData[0][10] = Bid;
      SignalEntry = SIGNAL_ENTRY_SELL;
   }

   //SignalEntry = SIGNAL_ENTRY_NEUTRAL;

   return SignalEntry;
}

ENUM_SIGNAL_EXIT SniperExit()
{ 
   //EXIT LOGIC

   //ACTIVE
   //BUY EXIT
   if (
      //AskThePlotsSniperExit(UpperTimeFrame + 10 + TradeExitPlot, 1, 1, "BUY_SNIPER_EXIT") == "EXIT A SNIPER TRADE BUY"
      AskThePlotsSniperExit(UpperTimeFrame + 10 + 10 + TradeExitPlot, 1, 1, "BUY_SNIPER_EXIT") == "EXIT A SNIPER TRADE BUY"
      //&& BuyStrategyActive == true 
      && BuyTradeActive == true

      //&& BuySafetyTrade2Strategy == true
      //&& Bid > EntryData[1][10] //current price is greater than the price it was entered at
      )
   {
      BuyTradeActive = false;

      Print("Ask/EntryData[0][10] in BUY_ST_EXIT: " + Ask + "/" + EntryData[0][10]);
      Print("EXIT A SNIPER TRADE BUY. SellStrategyActive: " + SellStrategyActive + 
      " BuyStrategyActive: " + BuyStrategyActive);
      
      SignalExit = SIGNAL_EXIT_BUY;
   }

   //ACTIVE
   //SELL EXIT
   if (
      //AskThePlotsSniperExit(UpperTimeFrame + 10 + TradeExitPlot, 1, 1, "SELL_SNIPER_EXIT") == "EXIT A SNIPER TRADE SELL"
      AskThePlotsSniperExit(UpperTimeFrame + 10 + 10 + TradeExitPlot, 1, 1, "SELL_SNIPER_EXIT") == "EXIT A SNIPER TRADE SELL"
      //&& SellStrategyActive == true 
      && SellTradeActive == true

      //&& SellSafetyTrade2Strategy == true
      //&& Bid > EntryData[1][10] //current price is greater than the price it was entered at
      )
   {
      SellTradeActive = false;
      //BuyBrRdDkRdStrategyActive = false;

      Print("Ask/EntryData[0][10] in SELL_SNIPER_EXIT: " + Ask + "/" + EntryData[0][10]);
      Print("EXIT A SNIPER TRADE SELL. SellStrategyActive: " + SellStrategyActive + 
      " BuyStrategyActive: " + BuyStrategyActive);
      
      SignalExit = SIGNAL_EXIT_SELL;
   }

   //SignalExit = SIGNAL_EXIT_NEUTRAL;

   return SignalExit;
}

string AskThePlotsSniperEntry(int Idx, int CndleStart, int CmbndHstryCandleLength, string OverallStrategy)
{
   string result = "";

   //ENTRY LOGIC

   //ACTIVE
   //BUY ENTRY SAFETY TRADE
   if (
      BuyStrategyActive == true 
      && OverallStrategy == "BUY_SNIPER_ENTRY"
      && SniperCockedHigh == true
      //&& BuySafetyTrade2Strategy == true

      //enter on sniper pink is increasing
      && CombinedHistory[CndleStart][Idx] >  CombinedHistory[CndleStart + 1][Idx]
      //and the last candle was less than or equal to 1
      && CombinedHistory[CndleStart + 1][Idx] <= 1
      )
   { 
      //Print(result);
      result = "ENTER A SNIPER TRADE BUY";
   }

   //ACTIVE
   //SELL ENTRY SAFETY TRADE
   if (
      SellStrategyActive == true 
      && OverallStrategy == "SELL_SNIPER_ENTRY"
      && SniperCockedLow == true
      //&& SellSafetyTrade2Strategy == true

      //enter on sniper pink is decreasing
      && CombinedHistory[CndleStart][Idx] <  CombinedHistory[CndleStart + 1][Idx]
      //and the last candle was less than or equal to 1
      && CombinedHistory[CndleStart + 1][Idx] >= 99
      )
   {  
      result = "ENTER A SNIPER TRADE SELL";
   }

   return result;
}

string AskThePlotsSniperExit(int Idx, int CndleStart, int CmbndHstryCandleLength, string OverallStrategy)
{
   string result = "";

   //EXIT LOGIC

   //BUY EXIT SAFETY TRADE
   if (
      OverallStrategy == "BUY_SNIPER_EXIT" 

      && 
         (  //typical take profit exit
            (CombinedHistory[CndleStart][Idx] < CombinedHistory[CndleStart + 1][Idx]
            && CombinedHistory[CndleStart + 1][Idx] > CombinedHistory[CndleStart + 2][Idx]

            //commented out the bid/ask restriction so I can exit early
            //if the macd goes bad
            && Bid > EntryData[1][10]
            && CombinedHistory[CndleStart][Idx] > 0)
         ||
            //
            (CombinedHistory[CndleStart][UpperTimeFrame + 10 + 6] 
            < CombinedHistory[CndleStart + 1][UpperTimeFrame + 10 + 6])
         /* ||
            //exit if the macd turns to avoid losses
            (CombinedHistory[0][UpperTimeFrame + 10 + 6] < 0) */
         )
      )
   {
      //Print("EXIT A SNIPER TRADE BUY");
      result = "EXIT A SNIPER TRADE BUY";
   }

   //SELL EXIT SAFETY TRADE
   if (
      OverallStrategy == "SELL_SNIPER_EXIT" 

      && 
         (  //typical take profit exit
            (CombinedHistory[CndleStart][Idx] > CombinedHistory[CndleStart + 1][Idx] 
            //commented out the bid/ask restriction so I can exit early
            //if the macd goes bad
            && Ask < EntryData[0][10]
            && CombinedHistory[CndleStart][Idx] < 0)
         ||
            //
            (CombinedHistory[CndleStart][UpperTimeFrame + 10 + 6] 
            > CombinedHistory[CndleStart + 1][UpperTimeFrame + 10 + 6])
         /* ||
            //exit if the macd turns to avoid losses
            (CombinedHistory[0][UpperTimeFrame + 10 + 6] > 0) */
         )
      )
   {
      //Print("Bid: " + Bid + " > EntryData[1][10]: " + EntryData[1][10]);
      result = "EXIT A SNIPER TRADE SELL";
   }

   return result;
}

/* //hump logic
      CombinedHistory[CndleStart][Idx] < CombinedHistory[CndleStart + 1][Idx]
      && CombinedHistory[CndleStart + 1][Idx] > CombinedHistory[CndleStart + 2][Idx]  */ 

//END DUTO STRATEGY, ENTRY AND EXIT

//===================================================