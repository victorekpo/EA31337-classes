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
#include "../Indicator.mqh"

#ifndef __MQL4__
// Defines global functions (for MQL4 backward compability).
double iATR(string _symbol, int _tf, int _period, int _shift) {
  ResetLastError();
  return Indi_ATR::iATR(_symbol, (ENUM_TIMEFRAMES)_tf, _period, _shift);
}
#endif

// Structs.
struct IndiATRParams : IndicatorParams {
  unsigned int period;
  // Struct constructors.
  IndiATRParams(unsigned int _period = 14, int _shift = 0)
      : period(_period), IndicatorParams(INDI_ATR, 1, TYPE_DOUBLE) {
    shift = _shift;
    SetDataValueRange(IDATA_RANGE_MIXED);
    SetCustomIndicatorName("Examples\\ATR");
  };
  IndiATRParams(IndiATRParams &_params, ENUM_TIMEFRAMES _tf) {
    THIS_REF = _params;
    tf = _tf;
  };
};

/**
 * Implements the Average True Range indicator.
 *
 * Note: It doesn't give independent signals. It is used to define volatility (trend strength).
 */
class Indi_ATR : public Indicator<IndiATRParams> {
 public:
  /**
   * Class constructor.
   */
  Indi_ATR(IndiATRParams &_p, IndicatorBase *_indi_src = NULL) : Indicator<IndiATRParams>(_p, _indi_src) {}
  Indi_ATR(ENUM_TIMEFRAMES _tf = PERIOD_CURRENT, int _shift = 0) : Indicator(INDI_ATR, _tf, _shift){};

  /**
   * Returns the indicator value.
   *
   * @docs
   * - https://docs.mql4.com/indicators/iatr
   * - https://www.mql5.com/en/docs/indicators/iatr
   */
  static double iATR(string _symbol, ENUM_TIMEFRAMES _tf, unsigned int _period, int _shift = 0,
                     IndicatorBase *_obj = NULL) {
#ifdef __MQL4__
    return ::iATR(_symbol, _tf, _period, _shift);
#else  // __MQL5__
    int _handle = Object::IsValid(_obj) ? _obj.Get<int>(IndicatorState::INDICATOR_STATE_PROP_HANDLE) : NULL;
    double _res[];
    if (_handle == NULL || _handle == INVALID_HANDLE) {
      if ((_handle = ::iATR(_symbol, _tf, _period)) == INVALID_HANDLE) {
        SetUserError(ERR_USER_INVALID_HANDLE);
        return EMPTY_VALUE;
      } else if (Object::IsValid(_obj)) {
        _obj.SetHandle(_handle);
      }
    }
    if (Terminal::IsVisualMode()) {
      // To avoid error 4806 (ERR_INDICATOR_DATA_NOT_FOUND),
      // we check the number of calculated data only in visual mode.
      int _bars_calc = BarsCalculated(_handle);
      if (GetLastError() > 0) {
        return EMPTY_VALUE;
      } else if (_bars_calc <= 2) {
        SetUserError(ERR_USER_INVALID_BUFF_NUM);
        return EMPTY_VALUE;
      }
    }
    if (CopyBuffer(_handle, 0, _shift, 1, _res) < 0) {
      return ArraySize(_res) > 0 ? _res[0] : EMPTY_VALUE;
    }
    return _res[0];
#endif
  }

  /**
   * Returns the indicator's value.
   */
  virtual IndicatorDataEntryValue GetEntryValue(int _mode = 0, int _shift = -1) {
    double _value = EMPTY_VALUE;
    int _ishift = _shift >= 0 ? _shift : iparams.GetShift();
    switch (iparams.idstype) {
      case IDATA_BUILTIN:
        _value = Indi_ATR::iATR(GetSymbol(), GetTf(), GetPeriod(), _ishift, THIS_PTR);
        break;
      case IDATA_ICUSTOM:
        _value = iCustom(istate.handle, GetSymbol(), GetTf(), iparams.GetCustomIndicatorName(), _mode, _ishift);
        break;
      default:
        SetUserError(ERR_INVALID_PARAMETER);
    }
    return _value;
  }

  /**
   * Returns reusable indicator for a given parameters.
   */
  static Indi_ATR *GetCached(string _symbol, ENUM_TIMEFRAMES _tf, int _period) {
    Indi_ATR *_ptr;
    string _key = Util::MakeKey(_symbol, (int)_tf, _period);
    if (!Objects<Indi_ATR>::TryGet(_key, _ptr)) {
      IndiATRParams _p(_period, _tf);
      _ptr = Objects<Indi_ATR>::Set(_key, new Indi_ATR(_p));
      _ptr.SetSymbol(_symbol);
    }
    return _ptr;
  }

  /* Getters */

  /**
   * Get period value.
   */
  unsigned int GetPeriod() { return iparams.period; }

  /* Setters */

  /**
   * Set period value.
   */
  void SetPeriod(unsigned int _period) {
    istate.is_changed = true;
    iparams.period = _period;
  }
};
