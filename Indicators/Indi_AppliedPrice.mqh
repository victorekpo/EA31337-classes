//+------------------------------------------------------------------+
//|                                                EA31337 framework |
//|                                 Copyright 2016-2021, EA31337 Ltd |
//|                                       https://github.com/EA31337 |
//+------------------------------------------------------------------+

/*
 * This file is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 */

// Includes.
#include "../BufferStruct.mqh"
#include "../Indicator.mqh"

// Structs.
struct AppliedPriceParams : IndicatorParams {
  ENUM_APPLIED_PRICE applied_price;
  // Struct constructor.
  AppliedPriceParams(ENUM_APPLIED_PRICE _applied_price = PRICE_OPEN, int _shift = 0)
      : IndicatorParams(INDI_APPLIED_PRICE, 1, TYPE_DOUBLE) {
    applied_price = _applied_price;
    SetDataSourceType(IDATA_INDICATOR);
    SetDataValueRange(IDATA_RANGE_PRICE);
    shift = _shift;
  };
  AppliedPriceParams(AppliedPriceParams &_params, ENUM_TIMEFRAMES _tf) {
    THIS_REF = _params;
    tf = _tf;
  };
};

/**
 * Implements the "Applied Price over OHCL Indicator" indicator, e.g. over Indi_Price.
 */
class Indi_AppliedPrice : public Indicator<AppliedPriceParams> {
 public:
  /**
   * Class constructor.
   */
  Indi_AppliedPrice(AppliedPriceParams &_p, IndicatorBase *_indi_src = NULL)
      : Indicator<AppliedPriceParams>(_p, _indi_src){};
  Indi_AppliedPrice(ENUM_TIMEFRAMES _tf = PERIOD_CURRENT) : Indicator(INDI_PRICE, _tf){};

  static double iAppliedPriceOnIndicator(IndicatorBase *_indi, ENUM_APPLIED_PRICE _applied_price, int _shift = 0) {
    double _ohlc[4];
    _indi[_shift].GetArray(_ohlc, 4);
    return BarOHLC::GetAppliedPrice(_applied_price, _ohlc[0], _ohlc[1], _ohlc[2], _ohlc[3]);
  }

  /**
   * Returns the indicator's value.
   */
  virtual double GetValue(int _mode = 0, int _shift = 0) {
    ResetLastError();
    double _value = EMPTY_VALUE;
    switch (iparams.idstype) {
      case IDATA_INDICATOR:
        if (HasDataSource()) {
          // Future validation of indi_src will check if we set mode for source indicator
          // (e.g. for applied price of Indi_Price).
          iparams.SetDataSourceMode(GetAppliedPrice());
        } else {
          Print("Indi_AppliedPrice requires source indicator to be set via SetDataSource()!");
          DebugBreak();
        }

        // @fixit
        /*
        if (indi_src.GetParams().GetMaxModes() != 4) {
          Print("Indi_AppliedPrice indicator requires that has at least 4 modes/buffers (OHLC)!");
          DebugBreak();
        }
        */
        _value = Indi_AppliedPrice::iAppliedPriceOnIndicator(GetDataSource(), GetAppliedPrice(), _shift);
        break;
      default:
        SetUserError(ERR_INVALID_PARAMETER);
    }
    istate.is_ready = _LastError == ERR_NO_ERROR;
    istate.is_changed = false;
    return _value;
  }

  /* Getters */

  /**
   * Get applied price.
   */
  ENUM_APPLIED_PRICE GetAppliedPrice() { return iparams.applied_price; }

  /* Setters */

  /**
   * Get applied price.
   */
  void SetAppliedPrice(ENUM_APPLIED_PRICE _applied_price) {
    istate.is_changed = true;
    iparams.applied_price = _applied_price;
  }
};
