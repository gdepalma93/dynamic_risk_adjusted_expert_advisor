//+------------------------------------------------------------------+
//|                                                MarketTrapper.mq4 |
//|                              Copyright 2014, JimdandyMql4Courses |
//|                               http://www.jimdandymql4courses.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2014, JimdandyMql4Courses"
#property link      "http://www.jimdandymql4courses.com"
#property version   "1.00"
#property strict
#include <stderror.mqh>
#include <stdlib.mqh>

extern double StopLoss=25;
extern double TakeProfit=50;
extern double MartingaleAmount = 1.5;
extern bool UseSmartingale =true;
input double   LotSize=0.1;//The Lotsize you would like to use.
extern int strayAmount=20;//How many pips outside of BBand to trigger.
extern int MagicSeed=1000;//Number from which to compute MagicNumber
input string  Password = "HolyGrail";//Please Enter Your Password.
int magic;
double pips;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   if(UseSmartingale)
      MartingaleAmount=(StopLoss+TakeProfit)/TakeProfit;
      Comment("The Martingale is set to: ",MartingaleAmount);
   magic = MagicNumberGenerator();
      // Determine what a pip is.
   pips =Point; //.00001 or .0001. .001 .01.
   if(Digits==1||Digits==3||Digits==5)
   pips*=10;
   #include<InitChecks.mqh>
//---
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
//---
      if(TotalOpenOrders()==0){
         if(OrderSelect(lastTradeTicket(),MODE_HISTORY))
            if(OrderProfit()<0){
               EnterOppositeTrade(OrderType(),OrderLots());
            return;
            }
         CheckForSignal();
      }   
  }
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
   //do the 5 character cfd's
   else mySymbol=StringSubstr(mySymbol,0,5);
   if(mySymbol      == "GER30")     pairNumber=33;
   else if(mySymbol == "FRA40")     pairNumber=34;
   //do the 4 characther cfd's
   else mySymbol=StringSubstr(mySymbol,0,4);
   if(mySymbol == "US30")      pairNumber=35;
   
   GeneratedNumber=MagicSeed+(pairNumber*1000)+_Period;
   return(GeneratedNumber);
  }
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//|       TRIGGER FUNCTION                                                           |
//+------------------------------------------------------------------+
void CheckForSignal(){
      double currentupper = iBands(NULL,0,20,2,0,0,1,0);
      double currentlower = iBands(NULL,0,20,2,0,0,2,0);
      if(Ask < currentlower-strayAmount*pips)EnterTrade(OP_BUY);
      if(Bid > currentupper+strayAmount*pips)EnterTrade(OP_SELL);
}
//+------------------------------------------------------------------+
//|     TRADE PLACING FUNCTION                                                             |
//+------------------------------------------------------------------+
void EnterTrade(int type){

   int err=0;
   double price=Bid,
          sl=0, 
          tp=0,
          lotsize = LotSize;
   if(type == OP_BUY)
      price =Ask;
   //----
   int ticket =  OrderSend(Symbol(),type,lotsize,price,30,0,0,"Ricochet Trade",magic,0,Magenta); 
   if(ticket>0){
      if(OrderSelect(ticket,SELECT_BY_TICKET)){
         sl = OrderOpenPrice()+(StopLoss*pips);
         if(StopLoss==0)sl=0;
         tp = OrderOpenPrice()-(TakeProfit*pips);
         if(OrderType()==OP_BUY){
            sl = OrderOpenPrice()-(StopLoss*pips);
            if(StopLoss==0)sl=0;
            tp = OrderOpenPrice()+(TakeProfit*pips);
         }
         if(!OrderModify(ticket,price,sl,tp,0,Magenta)) {
            err = GetLastError();
            Print("Encountered an error during modification!"+(string)err+" "+ErrorDescription(err)  );
         }
      }
      else{//in case it fails to select the order for some reason 
         Print("Failed to Select Order ",ticket);
         err = GetLastError();
         Print("Encountered an error while seleting order "+(string)ticket+" error number "+(string)err+" "+ErrorDescription(err)  );
      }
   }
   else{//in case it fails to place the order and send us back a ticket number.
      err = GetLastError();
      Print("Encountered an error during order placement!"+(string)err+" "+ErrorDescription(err)  );
      if(err==ERR_TRADE_NOT_ALLOWED)MessageBox("You can not place a trade because \"Allow Live Trading\" is not checked in your options. Please check the \"Allow Live Trading\" Box!","Check Your Settings!");
   }
}
//+------------------------------------------------------------------+
//|     OPPOSITE TRADE PLACING FUNCTION                                                             |
//+------------------------------------------------------------------+
void EnterOppositeTrade(int type, double lots){

   int err=0;
   double price=Bid,sl=0,tp=0,lotsize = lots * MartingaleAmount;
   if(type == OP_SELL)
      {price =Ask;type = OP_BUY;}
   else type = OP_SELL;
   //----
   int ticket =  OrderSend(Symbol(),type,lotsize,price,30,0,0,"MarketTrapper Trade",magic,0,Magenta); 
   if(ticket>0){
      if(OrderSelect(ticket,SELECT_BY_TICKET)){
         sl = OrderOpenPrice()+(StopLoss*pips);
         if(StopLoss==0)sl=0;
         tp = OrderOpenPrice()-(TakeProfit*pips);
         if(OrderType()==OP_BUY){
            sl = OrderOpenPrice()-(StopLoss*pips);
            if(StopLoss==0)sl=0;
            tp = OrderOpenPrice()+(TakeProfit*pips);
         }
         if(!OrderModify(ticket,price,sl,tp,0,Magenta)) {
            err = GetLastError();
            Print("Encountered an error during modification!"+(string)err+" "+ErrorDescription(err)  );
         }
      }
      else{//in case it fails to select the order for some reason 
         Print("Failed to Select Order ",ticket);
         err = GetLastError();
         Print("Encountered an error while seleting order "+(string)ticket+" error number "+(string)err+" "+ErrorDescription(err)  );
      }
   }
   else{//in case it fails to place the order and send us back a ticket number.
      err = GetLastError();
      Print("Encountered an error during order placement!"+(string)err+" "+ErrorDescription(err)  );
      if(err==ERR_TRADE_NOT_ALLOWED)MessageBox("You can not place a trade because \"Allow Live Trading\" is not checked in your options. Please check the \"Allow Live Trading\" Box!","Check Your Settings!");
   }
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
//Total of ALL orders place by this expert.
//+------------------------------------------------------------------+
int TotalOpenOrders()
{
  int total=0;
   for(int i=OrdersTotal()-1; i >= 0; i--)
	  {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)){
         if(OrderMagicNumber()== magic)
            total++;
      }
	   else Print("Failed to select order",GetLastError());
	  }
	  return (total);
}
