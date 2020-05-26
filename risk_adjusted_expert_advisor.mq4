//+------------------------------------------------------------------+
//|                                 risk_adjusted_expert_advisor.mq4 |
//|                                Copyright 2020, DePalma Solutions |
//|                                                 grantdepalma.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, DePalma Solutions"
#property link      "grant.win"
#property version   "1.00"
#property strict
#include <stderror.mqh>
#include <stdlib.mqh>

//--- input parameters
extern double risk=0.02;
extern int RR=3;
extern int minaccountrisk = 0.4;
extern int fastMAPeriod=10;
extern int slowMAPeriod=21;
extern int MaxAmountOfTrades=3;
extern bool HedgingAllowed=True;
extern int Slippage=30;
extern int MagicSeed=1000;
input string  Password="HolyGrail";//Please Enter Your Password.
double pips;
int magic=0;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   magic=MagicNumberGenerator();
   Print("MagicNumber is ",magic);
   HideTestIndicators(false);
// Determine what a pip is.
   pips=Point; //.00001 or .0001. .001 .01.
   if(Digits==3 || Digits==5)
      pips*=10;
   Comment(pips);
//#include<InitChecks.mqh>
   Comment("Expert Loaded Successfully");
   return(INIT_SUCCEEDED);
   }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {

//---
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
  CheckForSignal(); 
  OnTickDashboard(CurrentTradeTicket());
  }
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//|       TRIGGER FUNCTION                                                           |
//+------------------------------------------------------------------+
void CheckForSignal()
  {
   static datetime candletime=0;
   if(candletime!=Time[0]){
      //if(System==2)
        {
         double currentFastMA = iMA(NULL,0, fastMAPeriod,0, MODE_EMA, PRICE_WEIGHTED,1);
         double previousFastMA = iMA(NULL,0, fastMAPeriod,0, MODE_EMA, PRICE_WEIGHTED,2);
         double currentSlowMA = iMA(NULL,0, slowMAPeriod,0, MODE_EMA, PRICE_WEIGHTED,1);
         double previousSlowMA = iMA(NULL,0, slowMAPeriod,0, MODE_EMA, PRICE_WEIGHTED,2);
         
   
         if(currentFastMA>currentSlowMA && previousFastMA<previousSlowMA){
            if(TotalOpenOrders()>0){
               exitsells();
               }
            PlaceOrderBuy();
         }
         if(currentFastMA<currentSlowMA && previousFastMA>previousSlowMA){
            if(TotalOpenOrders()>0){
               exitbuys();
               }
            PlaceOrderSell();
         }
      }
      candletime=Time[0];
     }
  }
  
double UnitSize(double Risk){
   static double UnitSize=0;
   double chartN = iATR(NULL,0,20,1);
   double chartDollarVol = chartN/(Point*MarketInfo(NULL,MODE_TICKVALUE));
   UnitSize=((Risk/2))*AccountEquity()/chartDollarVol; //Reps 1% of Account
   return(UnitSize);
   } 
   
//+------------------------------------------------------------------+
//|   FUNCTION THAT PLACES BUY ORDER                                 |
//+------------------------------------------------------------------+
void PlaceOrderBuy()
  {
   if(OrderSend(_Symbol,OP_BUY,UnitSize(risk),Ask,3,0,0, "Buy Trade")==-1)
      Print("unable to place buy order due to \"",ErrorDescription(GetLastError()),"\"");
  }
  
//+------------------------------------------------------------------+
//|  FUNCTION THAT PLACES SELL ORDER                                 |
//+------------------------------------------------------------------+
void PlaceOrderSell()
  {
   if(OrderSend(_Symbol,OP_SELL,UnitSize(risk),Bid,3,0,0,"Sell Trade")==-1)
      Print("unable to place sell order due to \"",ErrorDescription(GetLastError()),"\"");
  }
 

//+------------------------------------------------------------------+
//|  Finds Current Trade Ticket Number                                                                |
//+------------------------------------------------------------------+

int CurrentTradeTicket()
  {
   int ticket=0;
   for(int i=0; i<OrdersTotal(); i++)
     {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES))
        {
         if(OrderSymbol()==_Symbol)
           {
            if(OrderType()==OP_SELL || OrderType()==OP_BUY){
               ticket=OrderTicket();
               break;
            }
           }
        }

     }
   return(ticket);
  }
  
//+------------------------------------------------------------------+
//Total of ALL orders place by this expert.
//+------------------------------------------------------------------+
int TotalOpenOrders()
{
  int total=0;
   for(int i=OrdersTotal()-1; i >= 0; i--)
	  {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES))
      {
         if(OrderMagicNumber()== magic)
            total++;
      }
	   else Print("Failed to select order",GetLastError());
	  }
	  return (total);
}

//+---------------------------------------------------------------------+
//|Function to determine how many trades of a certain type we have open.|
//+---------------------------------------------------------------------+
int OpenOrders(int dir)
  {
   int total=0;
   for(int i=OrdersTotal()-1; i>=0; i--)
     {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES))
         if(OrderMagicNumber()==magic)
            if(OrderType()==dir)
               total++;
      else Print("Failed to select order",GetLastError());
     }
   return (total);
  }
 
//+------------------------------------------------------------------+
//|Gets Ticket Number of this Ea's last closed trade.                |
//+------------------------------------------------------------------+
int lastTradeTicket(){
   int ticket = -1;
   for(int i=OrdersHistoryTotal()-1; i>=0; i--){
      if(OrderSelect(i,SELECT_BY_POS,MODE_HISTORY))
         if(OrderMagicNumber()== magic){
               ticket = OrderTicket();
               break;               
          }
   }//for

   return(ticket);
   }   

//+------------------------------------------------------------------+
//|Function to exit buys                                                                  |
//+------------------------------------------------------------------+
void exitbuys()
  {
   for(int i=0; i<OrdersTotal(); i++)
     {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES))
        {
         if(OrderSymbol()== Symbol())
            if(OrderType()==OP_BUY)
              {
               int attempts=1;
               while(attempts<=5)
                 {
                  int err=0;
                  bool result=OrderClose(OrderTicket(),OrderLots(),Bid,Slippage,Red);
                  if(result)
                    {
                     i--;
                     break;
                    }
                  else
                    {
                     err=GetLastError();
                     Print("LastError = ",ErrorDescription(err));
                     if(err==4108)break; // invalid ticket. break out of while loop
                     switch(err)
                       {
                        case 135: //Price Changed.
                        case 136: //Off Quotes.
                        case 137: //Broker Busy
                        case 138: //Requote
                        case 146: //Trade Context Busy
                           Sleep(1000);
                           RefreshRates();//will do these things if any of these five are the case and then break below
                        default:break;//break out of switch 
                       }//switch
                    }//else
                  attempts++;
                  if(attempts==6)
                     Print("Could not close trades after 5 attempts.",ErrorDescription(err));
                 }//while
              }//OP_BUY
        }//OrderSelect
      else Print("When selecting a trade, error ",GetLastError()," occurred");//OrderSelect returned false   
     }//for
  }
//+------------------------------------------------------------------+
//|Function to exit sells                                                                  |
//+------------------------------------------------------------------+

void exitsells()
  {
   for(int i=0; i<OrdersTotal(); i++)
     {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES))
        {
         if(OrderSymbol()==Symbol())
            if(OrderType()==OP_SELL)
              {
               int attempts=1;
               while(attempts<=5)
                 {
                  int err=0;
                  bool result=OrderClose(OrderTicket(),OrderLots(),Ask,Slippage,Red);
                  if(result)
                    {
                     i--;
                     break;
                    }
                  else
                    {
                     err=GetLastError();
                     Print("LastError = ",ErrorDescription(err));
                     if(err==4108)break; // invalid ticket. break out of while loop
                     switch(err)
                       {
                        case 135: //Price Changed.
                        case 136: //Off Quotes.
                        case 137: //Broker Busy
                        case 138: //Requote
                        case 146: //Trade Context Busy
                           Sleep(1000);
                           RefreshRates();//will do these things if any of these five are the case and then break below
                        default:break;//break out of switch 
                       }//switch
                    }//else
                  attempts++;
                  if(attempts==6)
                     Print("Could not close trades after 5 attempts.",ErrorDescription(err));
                 }//while
              }//OP_SELL
        }//OrderSelect
      else Print("When selecting a trade, error ",GetLastError()," occurred");//OrderSelect returned false   

     }//for



  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|   Comment Function                                                               |
//+------------------------------------------------------------------+
void OnTickDashboard(int ticket){
   if(OrderSelect(ticket,SELECT_BY_TICKET))
     {
      //double PSar_c=iSAR(NULL,0,Step,Maximum,0);
      double op=OrderOpenPrice();
      double lotsize=OrderLots();
      double stoploss=OrderStopLoss();
      double type=OrderType();
      string symbol=OrderSymbol();
      double targetbuy=op+(op-stoploss);
      double targetsell=op-(stoploss-op);
      double riskmBuy=10*lotsize*(op-stoploss)/pips;
      double riskmSell= 10*lotsize*(stoploss-op)/pips;
      double riskpBuy =(riskmBuy/AccountEquity())*100;
      double riskpSell=(riskmSell/AccountEquity())*100;
      double rewardmBuy=10*lotsize*(targetbuy-op)/pips;
      double rewardmSell= 10*lotsize*(op-targetsell)/pips;
      double rewardpBuy =(rewardmBuy/AccountEquity())*100;
      double rewardpSell=(rewardmSell/AccountEquity())*100;


      string line1="GDP Expert EA\n",
      line2b="Type: BUY\n",
      line2s="Type: Sell\n",
      line3="LotSize: %G\n",
      line4="Risk : %G\n",
      line5="Risk $: %G\n",
      line6="Reward : %G\n",
      line7="Reward $: %G\n",
      line8="Target Price: %G\n",
      line9="StopLoss1: %G\n";
      //line10="Trailing Stop: %G";



      if(type==OP_BUY)
        {
         Comment(StringFormat(line1+line2b+line3+line4+line5+line6+line7+line8+line9,lotsize,riskpBuy,riskmBuy,rewardpBuy,rewardmBuy,targetbuy,stoploss));
        }
      else if(type==OP_SELL)
        {
         Comment(StringFormat(line1+line2s+line3+line4+line5+line6+line7+line8+line9,lotsize,riskpSell,riskmSell,rewardpSell,rewardmSell,targetsell,stoploss));
        }
   }
}

 

//+------------------------------------------------------------------+
//|        Magic Number Generator                                                          |
//+------------------------------------------------------------------+

int MagicNumberGenerator()
  {
   string mySymbol=StringSubstr(_Symbol,0,6);
   int pairNumber=0;
   int GeneratedNumber=0;
   if(mySymbol=="AUDCAD") pairNumber=1;
   else if(mySymbol == "AUDCHF")    pairNumber=2;
   else if(mySymbol == "AUDJPY")    pairNumber=3;
   else if(mySymbol == "AUDNZD")    pairNumber=4;
   else if(mySymbol == "AUDUSD")    pairNumber=5;
   else if(mySymbol == "CADCHF")    pairNumber=6;
   else if(mySymbol == "CADJPY")    pairNumber=7;
   else if(mySymbol == "CHFJPY")    pairNumber=8;
   else if(mySymbol == "EURAUD")    pairNumber=9;
   else if(mySymbol == "EURCAD")    pairNumber=10;
   else if(mySymbol == "EURCHF")    pairNumber=11;
   else if(mySymbol == "EURGBP")    pairNumber=12;
   else if(mySymbol == "EURJPY")    pairNumber=13;
   else if(mySymbol == "EURNZD")    pairNumber=14;
   else if(mySymbol == "EURUSD")    pairNumber=15;
   else if(mySymbol == "GBPAUD")    pairNumber=16;
   else if(mySymbol == "GBPCAD")    pairNumber=17;
   else if(mySymbol == "GBPCHF")    pairNumber=18;
   else if(mySymbol == "GBPJPY")    pairNumber=19;
   else if(mySymbol == "GBPNZD")    pairNumber=20;
   else if(mySymbol == "GBPUSD")    pairNumber=21;
   else if(mySymbol == "NZDCAD")    pairNumber=22;
   else if(mySymbol == "NZDJPY")    pairNumber=23;
   else if(mySymbol == "NZDCHF")    pairNumber=24;
   else if(mySymbol == "NZDUSD")    pairNumber=25;
   else if(mySymbol == "USDCAD")    pairNumber=26;
   else if(mySymbol == "USDCHF")    pairNumber=27;
   else if(mySymbol == "USDJPY")    pairNumber=28;
   else if(mySymbol == "XAGUSD")    pairNumber=29;
   else if(mySymbol == "XAUUSD")    pairNumber=30;
   else if(mySymbol == "SPX500")    pairNumber=31;
   else if(mySymbol == "AUS200")    pairNumber=32;
   // CryptoUSD
   else if(mySymbol == "BTCUSD")    pairNumber=33;
   else if(mySymbol == "ETHUSD")    pairNumber=34;
   else if(mySymbol == "LTCUSD")    pairNumber=35;
   else if(mySymbol == "BCHUSD")    pairNumber=36;
   else if(mySymbol == "EOSUSD")    pairNumber=37;
   else if(mySymbol == "XRPUSD")    pairNumber=38;
   else if(mySymbol == "DASHUSD")    pairNumber=39;
   else if(mySymbol == "XMRUSD")    pairNumber=40;
   else if(mySymbol == "NEOUSD")    pairNumber=41;
   else if(mySymbol == "ZECUSD")    pairNumber=42;
   else if(mySymbol == "IOTAUSD")    pairNumber=43;
   else if(mySymbol == "OMGUSD")    pairNumber=44;
   else if(mySymbol == "ETPUSD")    pairNumber=57;
   else if(mySymbol == "EDOUSD")    pairNumber=58;
   // CryptoBTC
   else if(mySymbol == "BCHBTC")    pairNumber=45;
   else if(mySymbol == "DASHBTC")    pairNumber=46;
   else if(mySymbol == "ETHBTC")    pairNumber=47;
   else if(mySymbol == "LTCBTC")    pairNumber=48;
   else if(mySymbol == "NEOBTC")    pairNumber=49;
   else if(mySymbol == "XMRBTC")    pairNumber=50;
   else if(mySymbol == "ZECBTC")    pairNumber=51;
   // Indeces
   else if(mySymbol == "SPX500")    pairNumber=52;
   else if(mySymbol == "US30")    pairNumber=53;
   else if(mySymbol == "NAS100")    pairNumber=54;
   else if(mySymbol == "JPN225")    pairNumber=55;
   else if(mySymbol == "AUS200")    pairNumber=56;
   // Stocks
   //else if(mySymbol == "AAPL")
   //else if(mySymbol == "BABA")

//do the 5 character cfd's
   else mySymbol=StringSubstr(mySymbol,0,5);
   if(mySymbol      == "GER30")     pairNumber=33;
   else if(mySymbol == "FRA40")     pairNumber=34;
//do the 4 characther cfd's
   else mySymbol=StringSubstr(mySymbol,0,4);
   if(mySymbol=="US30") pairNumber=35;

   GeneratedNumber=MagicSeed+(pairNumber*1000)+_Period;
   return(GeneratedNumber);
  }
  





