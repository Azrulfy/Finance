#property copyright "Copyright © 2016, Tolga Gölbaşı"
#property show_inputs
#import "kernel32.dll"
    int WinExec(string NameEx, int dwFlags);
#import
#import "shell32.dll"
int ShellExecuteA(int hWnd,int lpVerb,string lpFile,int lpParameters,int lpDirectory,int nCmdShow);
#import
#include <Files\File.mqh>
#include <WinUser32.mqh>  
#include <Files\FileTxt.mqh>
#define SW_HIDE             0
#define SW_SHOWNORMAL       1
#define SW_NORMAL           1
#define SW_SHOWMINIMIZED    2
#define SW_SHOWMAXIMIZED    3
#define SW_MAXIMIZE         3
#define SW_SHOWNOACTIVATE   4
#define SW_SHOW             5
#define SW_MINIMIZE         6
#define SW_SHOWMINNOACTIVE  7
#define SW_SHOWNA           8
#define SW_RESTORE          9
#define SW_SHOWDEFAULT      10
#define SW_FORCEMINIMIZE    11
#define SW_MAX              11
//--------------------------------------------------------------------
extern int     Magic       = 123456;     
extern bool    SELL        = false,
               BUY         = false;
extern int     slippage    = 3;
extern double Lot;
extern double Kelly = 20;
//--------------------------------------------------------------------
double SL,TP;

string    ExtFileName; // ="XXXXXX_PERIOD.CSV";
//--------------------------------------------------------------------
int start()
{
   int lastorder = 0;
   int multiplier = 0;
   double estimatedPrice;
   int file_handle;
   while (true)
   {
      file_handle = FileOpen("buyorsell.txt",FILE_READ|FILE_TXT|FILE_ANSI,",");
      if(file_handle!=INVALID_HANDLE)
      {
         break;
      }
      Sleep(5);
   }
   if(file_handle!=INVALID_HANDLE)
   {
      //--- read data from the file
      while(!FileIsEnding(file_handle))
      {
         int str_size=FileReadInteger(file_handle,INT_VALUE);
         //--- read the string
         string str = FileReadString(file_handle,str_size);
         estimatedPrice = StrToDouble(str);
      }
      FileClose(file_handle);
   }
   while (true) 
   {
      double spread = MarketInfo(Symbol(),MODE_SPREAD);
      int digits = SymbolInfoInteger(Symbol(),SYMBOL_DIGITS);
      datetime time = TimeCurrent();
      MqlDateTime str1;
      TimeToStruct(time,str1);      
      double Cur_Min = str1.min;
      double Cur_Sec = str1.sec;
      double Cur_Hour = str1.hour;
      if (((MathMod(Cur_Hour,4) == 0)) && Cur_Min == 0 && Cur_Sec == 0)
      {
         myhist();
         Sleep(1000);
         while (true)
         {
            file_handle = FileOpen("buyorsell.txt",FILE_READ|FILE_TXT|FILE_ANSI,",");
            if(file_handle!=INVALID_HANDLE)
            {
               break;
            }
            Sleep(50);
         }
         if(file_handle!=INVALID_HANDLE)
         {
            //--- read data from the file
            while(!FileIsEnding(file_handle))
            {
               str_size=FileReadInteger(file_handle,INT_VALUE);
               //--- read the string
               str = FileReadString(file_handle,str_size);
               estimatedPrice = StrToDouble(str);
            }
            FileClose(file_handle);
         }
         RefreshRates();
         double openPrice = iOpen(Symbol(),Period(),0);
         if (estimatedPrice!=0)
         {
            if ((estimatedPrice - openPrice) > spread*multiplier*pow(0.1,digits))
            {
               if(lastorder != 1)
               {
                  closeall();
                  lastorder = 1;
                  OPENORDER ("Buy",estimatedPrice);
               }
            }
            else if ((openPrice - estimatedPrice) > spread*multiplier*pow(0.1,digits))
            {
               if(lastorder != 0)
               {
                  closeall();
                  lastorder = 0;
                  OPENORDER ("Sell",estimatedPrice);
               }

            }
            else
            {
               closeall();
               lastorder = 2;
            }
         }
      }
      Sleep(50);
   }
return(0);
}
//--------------------------------------------------------------------
void OPENORDER(string ord,double estimatedPrice)
{
   int error;
   while (true)
   {  
      RefreshRates();
      Lot = 30000/((100/Kelly)*1000*Bid);
     // Lot = 7;
      error=true;
      double stoploss=0;//NormalizeDouble(estimatedPrice*Point,Digits);
      double takeprofit=0;//NormalizeDouble(estimatedPrice*Point,Digits);
      if (ord=="Buy" )
         error=OrderSend(Symbol(),OP_BUY, Lot,Ask,slippage,stoploss,takeprofit,"",Magic,3,Blue);
      if (ord=="Sell") 
         error=OrderSend(Symbol(),OP_SELL, Lot,Bid,slippage,stoploss,takeprofit,"",Magic,3,Red);
      if(error<0)
      {
        Alert("OrderSend failed with error #",GetLastError());
      }
      else
      {
        Alert("OrderSend placed successfully");
        return;
      }
      Sleep(100);

   }
   return;
}                  
//--------------------------------------------------------------------
void closeall()
{
  int total = OrdersTotal();
  for(int i=total-1;i>=0;i--)
  {
    OrderSelect(i, SELECT_BY_POS);
    int type   = OrderType();

    bool result = false;
    
    switch(type)
    {
      //Close opened long positions
      case OP_BUY       : result = OrderClose( OrderTicket(), OrderLots(), MarketInfo(OrderSymbol(), MODE_BID), 5, Red );
                          break;
      
      //Close opened short positions
      case OP_SELL      : result = OrderClose( OrderTicket(), OrderLots(), MarketInfo(OrderSymbol(), MODE_ASK), 5, Red );
                          break;

      //Close pending orders
      case OP_BUYLIMIT  :
      case OP_BUYSTOP   :
      case OP_SELLLIMIT :
      case OP_SELLSTOP  : result = OrderDelete( OrderTicket() );
    }
    
    if(result == false)
    {
      Alert("Order " , OrderTicket() , " failed to close. Error:" , GetLastError() );
      Sleep(1000);
    }  
  }
}

void myhist()
  {
      CFileTxt     File;
      MqlRates  rates_array[];
      string sSymbol = Symbol();
      Comment("WORKING... wait... ");
      // prepare file name, for example, EURUSD1
      ExtFileName=sSymbol;
      StringConcatenate(ExtFileName,sSymbol,".csv");
      ArraySetAsSeries(rates_array,true);
      int iMaxBar=TerminalInfoInteger(TERMINAL_MAXBARS);
      string format="%G,%G,%G,%G,%d";
      int iCod;
      while (true)
      {
         datetime nextBarTime = TimeCurrent();
         string nextBarTimeString = TimeToString(nextBarTime,TIME_MINUTES);         
         iCod=CopyRates(sSymbol,PERIOD_H4,0,3000,rates_array);
         if (StringCompare(TimeToString(rates_array[0].time,TIME_MINUTES),nextBarTimeString) == 0)
         {
            break;
         }
         Sleep(50);
      }
      if(iCod>1)
        {
         // open file
         File.Open(ExtFileName,FILE_WRITE,9);
         for(int i=iCod-1; i>=0; i--)
           {
            // prepare a string:
            // 2009.01.05,12:49,1.36770,1.36780,1.36760,1.36760,8
            string sOut=StringFormat("%s",TimeToString(rates_array[i].time,TIME_DATE));
            sOut=sOut+","+TimeToString(rates_array[i].time,TIME_MINUTES);
            sOut=sOut+","+StringFormat(format,
                                       rates_array[i].open,
                                       rates_array[i].high,
                                       rates_array[i].low,
                                       rates_array[i].close,
                                       rates_array[i].tick_volume);
            sOut=sOut+"\n";
            File.WriteString(sOut);
   
           }
         File.Close();
        }
   Comment("OK. ready... ");
  }