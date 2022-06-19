/*
 * main_tp_final.c
 *
 *  Created on: Jun 13, 2022
 *      Author: sigui
 */


#include "xparameters.h"
#include "xil_io.h"
#include "filtroVentana_ip.h"


//====================================================

#define FILTROVENTANA_IP_S_AXI_SLV_BASE_ADDRESS	0x43C00000

#define IN_REG		FILTROVENTANA_IP_S_AXI_SLV_REG0_OFFSET
#define UMBRAL_REG	FILTROVENTANA_IP_S_AXI_SLV_REG1_OFFSET
#define CLK_REG		FILTROVENTANA_IP_S_AXI_SLV_REG2_OFFSET
#define RST_REG		FILTROVENTANA_IP_S_AXI_SLV_REG3_OFFSET
#define EN_REG		FILTROVENTANA_IP_S_AXI_SLV_REG4_OFFSET

#define OUT_REG		FILTROVENTANA_IP_S_AXI_SLV_REG5_OFFSET

#define BASE_ADDRESS	FILTROVENTANA_IP_S_AXI_SLV_BASE_ADDRESS


#define EN_FLAG		(1 << 0)
#define RST_FLAG	(1 << 0)
#define CLK_FLAG	(1 << 0)

#define UMBRAL		500

static uint32_t datos_in[] =
{
		100,200,300,400,300,350,400,450,400,350,
		1100,1200,1300,1400,1350,1400,1450,1400,
		300,250,300,200,250,350,400,600,500,700
};

uint32_t calcular_abs(uint32_t a, uint32_t b)
{
	if(a > b)
		return (a - b);
	else
		return (b - a);
}

int main (void) {

	uint32_t res;

	uint32_t cant = sizeof(datos_in)/sizeof(uint32_t);
	uint32_t i;
	uint32_t diff;

	xil_printf("Inicio del programa para validar el uso del IP core\r\n");
	xil_printf("de un filtro de ventana deslizante con umbral de autoreset--\r\n\r\n");

	FILTROVENTANA_IP_mWriteReg(BASE_ADDRESS, UMBRAL_REG, 500);

	xil_printf("Fijo un umbral de reset igual a %d \r\n", UMBRAL);

	FILTROVENTANA_IP_mWriteReg(BASE_ADDRESS, RST_REG, 0);
	FILTROVENTANA_IP_mWriteReg(BASE_ADDRESS, EN_REG, EN_FLAG);

	for(i = 0; i < cant; i++)
	{
		FILTROVENTANA_IP_mWriteReg(BASE_ADDRESS, IN_REG, datos_in[i]);

		FILTROVENTANA_IP_mWriteReg(BASE_ADDRESS, CLK_REG, CLK_FLAG);

		xil_printf("Dato in: %d \r\n", datos_in[i]);

		if(i > 0)
		{
			diff = calcular_abs(datos_in[i], datos_in[i-1]);

			if(diff > UMBRAL)
			{
				xil_printf("La diferencia entre %d y %d en mayor que el umbral %d \r\n", datos_in[i-1], datos_in[i], UMBRAL);
				xil_printf("El filtro se resetea automaticamente\r\n");
			}

		}

		FILTROVENTANA_IP_mWriteReg(BASE_ADDRESS, CLK_REG, 0);

		res = FILTROVENTANA_IP_mReadReg(BASE_ADDRESS, OUT_REG);

		xil_printf("Salida Filtro: %d \r\n", res);
	}

	FILTROVENTANA_IP_mWriteReg(BASE_ADDRESS, RST_REG, 1);
	xil_printf("-------------------------------------------------\r\n");
	xil_printf("Forzamos el reseteo del filtro \r\n");
	xil_printf("-------------------------------------------------\r\n");

	FILTROVENTANA_IP_mWriteReg(BASE_ADDRESS, CLK_REG, CLK_FLAG);
	FILTROVENTANA_IP_mWriteReg(BASE_ADDRESS, CLK_REG, 0);

	FILTROVENTANA_IP_mWriteReg(BASE_ADDRESS, RST_REG, 0);


	for(i = 0; i < cant/2; i++)
	{
		FILTROVENTANA_IP_mWriteReg(BASE_ADDRESS, IN_REG, datos_in[i]);

		FILTROVENTANA_IP_mWriteReg(BASE_ADDRESS, CLK_REG, CLK_FLAG);

		xil_printf("Dato in: %d \r\n", datos_in[i]);

		FILTROVENTANA_IP_mWriteReg(BASE_ADDRESS, CLK_REG, 0);

		res = FILTROVENTANA_IP_mReadReg(BASE_ADDRESS, OUT_REG);

		xil_printf("Salida Filtro: %d \r\n", res);
	}

	FILTROVENTANA_IP_mWriteReg(BASE_ADDRESS, EN_REG, 0);
	xil_printf("-------------------------------------------------\r\n");
	xil_printf("Bajamos la señal de Enable \r\n");
	xil_printf("-------------------------------------------------\r\n");

	for(i = cant/2; i < cant; i++)
	{
		FILTROVENTANA_IP_mWriteReg(BASE_ADDRESS, IN_REG, datos_in[i]);

		FILTROVENTANA_IP_mWriteReg(BASE_ADDRESS, CLK_REG, CLK_FLAG);

		xil_printf("Dato in: %d \r\n", datos_in[i]);

		FILTROVENTANA_IP_mWriteReg(BASE_ADDRESS, CLK_REG, 0);

		res = FILTROVENTANA_IP_mReadReg(BASE_ADDRESS, OUT_REG);

		xil_printf("Salida Filtro: %d \r\n", res);
	}

    xil_printf("Fin de la prueba");
}
