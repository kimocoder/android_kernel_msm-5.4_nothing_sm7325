/******************************************************************************
 *
 * Copyright(c) 2007 - 2017 Realtek Corporation.
 *
 * This program is free software; you can redistribute it and/or modify it
 * under the terms of version 2 of the GNU General Public License as
 * published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
 * more details.
 *
 *****************************************************************************/
#ifndef __PCI_HAL_H__
#define __PCI_HAL_H__

#ifdef CONFIG_RTL8188E
	void rtl8188ee_set_hal_ops(_adapter *padapter);
#endif

u8 rtw_set_hal_ops2(_adapter *padapter);
#endif /* __PCIE_HAL_H__ */
