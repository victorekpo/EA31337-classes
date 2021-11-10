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

// Ignore processing of this file if already included.
#ifndef INDICATOR_CANDLE_H
#define INDICATOR_CANDLE_H

#ifndef __MQL__
// Allows the preprocessor to include a header file when it is needed.
#pragma once
#endif

// Includes.
#include "../IndicatorBase.h"

/**
 * Class to deal with candle indicators.
 */
template <typename TS>
class IndicatorCandle : public IndicatorBase {
 protected:
  BufferStruct<IndicatorDataEntry> icdata;
  TS icparams;

 protected:
  /* Protected methods */

  /**
   * Initialize class.
   *
   * Called on constructor.
   */
  void Init() {
    icdata.AddFlags(DICT_FLAG_FILL_HOLES_UNSORTED);
    icdata.SetOverflowListener(IndicatorCandleOverflowListener, 10);
  }

 public:
  /* Special methods */

  /**
   * Class constructor.
   */
  IndicatorCandle(const TS& _icparams, IndicatorBase* _indi_src = NULL, int _indi_mode = 0) : icparams(_icparams) {
    if (_indi_src != NULL) {
      SetDataSource(_indi_src, _indi_mode);
    }
    Init();
  }
  IndicatorCandle(ENUM_INDICATOR_TYPE _itype = INDI_CANDLE, int _shift = 0, string _name = "") {
    icparams.SetIndicatorType(_itype);
    icparams.SetShift(_shift);
    Init();
  }

  /* Virtual method implementations */

  /**
   * Returns the indicator's data entry.
   *
   * @see: IndicatorDataEntry.
   *
   * @return
   *   Returns IndicatorDataEntry struct filled with indicator values.
   */
  IndicatorDataEntry GetEntry(int _timestamp = 0) {
    ResetLastError();
    IndicatorDataEntry _entry = icdata.GetByKey(_timestamp);
    if (!_entry.IsValid() && !_entry.CheckFlag(INDI_ENTRY_FLAG_INSUFFICIENT_DATA)) {
      _entry.Resize(icparams.GetMaxModes());
      _entry.timestamp = _timestamp;
      for (int _mode = 0; _mode < (int)icparams.GetMaxModes(); _mode++) {
        switch (icparams.GetDataValueType()) {
          case TYPE_BOOL:
          case TYPE_CHAR:
          case TYPE_INT:
            _entry.values[_mode] = GetValue<int>(_mode, _timestamp);
            break;
          case TYPE_LONG:
            _entry.values[_mode] = GetValue<long>(_mode, _timestamp);
            break;
          case TYPE_UINT:
            _entry.values[_mode] = GetValue<uint>(_mode, _timestamp);
            break;
          case TYPE_ULONG:
            _entry.values[_mode] = GetValue<ulong>(_mode, _timestamp);
            break;
          case TYPE_DOUBLE:
            _entry.values[_mode] = GetValue<double>(_mode, _timestamp);
            break;
          case TYPE_FLOAT:
            _entry.values[_mode] = GetValue<float>(_mode, _timestamp);
            break;
          case TYPE_STRING:
          case TYPE_UCHAR:
          default:
            SetUserError(ERR_INVALID_PARAMETER);
            break;
        }
      }
      GetEntryAlter(_entry, _timestamp);
      _entry.SetFlag(INDI_ENTRY_FLAG_IS_VALID, IsValidEntry(_entry));
      if (_entry.IsValid()) {
        icdata.Add(_entry, _timestamp);
        istate.is_changed = false;
        istate.is_ready = true;
      } else {
        _entry.AddFlags(INDI_ENTRY_FLAG_INSUFFICIENT_DATA);
      }
    }
    if (_LastError != ERR_NO_ERROR) {
      istate.is_ready = false;
      ResetLastError();
    }
    return _entry;
  }

  /**
   * Alters indicator's struct value.
   *
   * This method allows user to modify the struct entry before it's added to cache.
   * This method is called on GetEntry() right after values are set.
   */
  virtual void GetEntryAlter(IndicatorDataEntry& _entry, int _timestamp = -1) {
    _entry.AddFlags(_entry.GetDataTypeFlags(icparams.GetDataValueType()));
  };

  /**
   * Returns the indicator's entry value for the given shift and mode.
   *
   * @see: DataParamEntry.
   *
   * @return
   *   Returns DataParamEntry struct filled with a single value.
   */
  virtual IndicatorDataEntryValue GetEntryValue(int _mode = 0, int _shift = -1) {
    int _ishift = _shift >= 0 ? _shift : icparams.GetShift();
    return GetEntry(_ishift)[_mode];
  }

  /**
   * Function should return true if resize can be made, or false to overwrite current slot.
   */
  static bool IndicatorCandleOverflowListener(ENUM_DICT_OVERFLOW_REASON _reason, int _size, int _num_conflicts) {
    switch (_reason) {
      case DICT_OVERFLOW_REASON_FULL:
        // We allow resize if dictionary size is less than 86400 slots.
        return _size < 86400;
      case DICT_OVERFLOW_REASON_TOO_MANY_CONFLICTS:
      default:
        // When there is too many conflicts, we just reject doing resize, so first conflicting slot will be reused.
        break;
    }
    return false;
  }

  /**
   * Sets indicator data source.
   */
  void SetDataSource(IndicatorBase* _indi, int _input_mode = 0) {
    indi_src = _indi;
    icparams.SetDataSource(-1, _input_mode);
  }

  /* Virtual methods */

  /**
   * Checks if indicator entry is valid.
   *
   * @return
   *   Returns true if entry is valid (has valid values), otherwise false.
   */
  virtual bool IsValidEntry(IndicatorDataEntry& _entry) {
    bool _result = true;
    _result &= _entry.timestamp > 0;
    _result &= _entry.GetSize() > 0;
    if (_entry.CheckFlags(INDI_ENTRY_FLAG_IS_REAL)) {
      if (_entry.CheckFlags(INDI_ENTRY_FLAG_IS_DOUBLED)) {
        _result &= !_entry.HasValue<double>(DBL_MAX);
        _result &= !_entry.HasValue<double>(NULL);
      } else {
        _result &= !_entry.HasValue<float>(FLT_MAX);
        _result &= !_entry.HasValue<float>(NULL);
      }
    } else {
      if (_entry.CheckFlags(INDI_ENTRY_FLAG_IS_UNSIGNED)) {
        if (_entry.CheckFlags(INDI_ENTRY_FLAG_IS_DOUBLED)) {
          _result &= !_entry.HasValue<ulong>(ULONG_MAX);
          _result &= !_entry.HasValue<ulong>(NULL);
        } else {
          _result &= !_entry.HasValue<uint>(UINT_MAX);
          _result &= !_entry.HasValue<uint>(NULL);
        }
      } else {
        if (_entry.CheckFlags(INDI_ENTRY_FLAG_IS_DOUBLED)) {
          _result &= !_entry.HasValue<long>(LONG_MAX);
          _result &= !_entry.HasValue<long>(NULL);
        } else {
          _result &= !_entry.HasValue<int>(INT_MAX);
          _result &= !_entry.HasValue<int>(NULL);
        }
      }
    }
    return _result;
  }
};

#endif
