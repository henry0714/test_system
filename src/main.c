#include "stm32f30x_it.h"
#include "stm32f3_discovery.h"

/* FreeRTOS header files */
#include "FreeRTOS.h"
#include "task.h"
#include "queue.h"

/* Private variables ---------------------------------------------------------*/
RCC_ClocksTypeDef RCC_Clocks;

/* Private function prototypes -----------------------------------------------*/
void vLEDTask(void*);
static void prvSetupHardware(void);

/* Private functions ---------------------------------------------------------*/


/**
  * @brief  Main program.
  * @param  None 
  * @retval None
  */
int main(void)
{  
    TaskHandle_t xHandle = NULL;
    
    prvSetupHardware();
    xTaskCreate(vLEDTask, "LED", configMINIMAL_STACK_SIZE, NULL, tskIDLE_PRIORITY+3, &xHandle);
    configASSERT(xHandle);
    vTaskStartScheduler();
}

void vLEDTask(void* pvParameters)
{
    while(1)
    {
        STM_EVAL_LEDOn(LED3);
        vTaskDelay(100/portTICK_RATE_MS);
        STM_EVAL_LEDOff(LED3);
        vTaskDelay(100/portTICK_RATE_MS);
    }
    vTaskDelete(NULL);
}

/**
  * @brief  Configure the processor for use with the STM32F3-Discovery board.
  *         This includes setup for the I/O, system clock, and access timings.
  * @param  None
  * @retval None
  */
static void prvSetupHardware(void)
{
    /* SysTick end of count event each 10ms */
    RCC_GetClocksFreq(&RCC_Clocks);
    SysTick_Config(RCC_Clocks.HCLK_Frequency / 1000);

    /* Initialize LEDs on STM32F3-Discovery board */
    STM_EVAL_LEDInit(LED3);
    STM_EVAL_LEDInit(LED4);
    STM_EVAL_LEDInit(LED5);
    STM_EVAL_LEDInit(LED6);
    STM_EVAL_LEDInit(LED7);
    STM_EVAL_LEDInit(LED8);
    STM_EVAL_LEDInit(LED9);
    STM_EVAL_LEDInit(LED10);
}

#ifdef  USE_FULL_ASSERT

/**
  * @brief  Reports the name of the source file and the source line number
  *         where the assert_param error has occurred.
  * @param  file: pointer to the source file name
  * @param  line: assert_param error line source number
  * @retval None
  */
void assert_failed(uint8_t* file, uint32_t line)
{ 
    /* User can add his own implementation to report the file name and line number,
    ex: printf("Wrong parameters value: file %s on line %d\r\n", file, line) */
    
    /* Infinite loop */
    while(1)
    {
    }
}
#endif
