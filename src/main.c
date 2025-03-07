#include <libopencm3/stm32/gpio.h>
#include <libopencm3/stm32/rcc.h>

#include <stdio.h>

void delay(int32_t delay) {
    for (int i = 0; i < 100 * delay; i++){
        __asm__("nop");
    }
}

int main(void) {
    rcc_periph_clock_enable(RCC_GPIOB); 

    #if defined (STM32F4)
    gpio_mode_setup(GPIOB, GPIO_MODE_OUTPUT, GPIO_PUPD_NONE, GPIO2);
    #elif defined (STM32F1)
	gpio_set_mode(GPIOB, GPIO_MODE_OUTPUT_2_MHZ, GPIO_CNF_OUTPUT_PUSHPULL,  GPIO2);
    #endif
    for (;;) {
        gpio_toggle(GPIOB, GPIO2); // LED yak/söndür
        delay(100000);
    }
    return 0;
}
