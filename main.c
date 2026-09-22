/**
 ******************************************************************************
 * @file    main.c
 * @brief   STM32F103C8T6 最小系统核心板 —— 三灯流水灯（直接操作寄存器）
 *
 * 实验要求
 *   - 使用 GPIOA、GPIOB、GPIOC 三个端口的引脚，分别控制 3 个 LED
 *   - 引脚：PA4、PB5、PC13
 *   - 输出模式：通用推挽输出（CNF = 00）
 *   - 最高输出时钟频率：2MHz（MODE = 10）
 *   - 三灯轮流点亮，每个状态保持 1 秒，循环往复
 *
 * 状态流转（1 = 亮，0 = 灭）
 *   初始 0 0 0  →  状态一 1 0 0  →  状态二 0 1 0  →  状态三 0 0 1  →  回到状态一
 *
 * 说明
 *   - 本文件不依赖标准外设库（StdPeriph）与 CMSIS，寄存器地址全部自行定义，
 *     便于对照《STM32F10x 参考手册》第 8.5 节 GPIO 寄存器说明阅读。
 *   - 系统时钟采用芯片复位后的默认值：HSI 8MHz（未启动 PLL）。
 *     若后续改用 SystemInit 把主频配到 72MHz，请把 SYSCLK_HZ 改成 72000000。
 ******************************************************************************
 */

#include <stdint.h>

/* ==========================================================================
 * 一、寄存器地址定义
 * ========================================================================== */

#define PERIPH_BASE      0x40000000UL                     /* 外设基地址        */
#define APB2PERIPH_BASE  (PERIPH_BASE + 0x10000UL)        /* APB2 总线基地址   */

/*
 * 端口基地址（参考手册 8.5 节，端口地址范围见下表）
 *   GPIOA  0x4001 0800 - 0x4001 0BFF
 *   GPIOB  0x4001 0C00 - 0x4001 0FFF
 *   GPIOC  0x4001 1000 - 0x4001 13FF
 */
#define GPIOA_BASE       (APB2PERIPH_BASE + 0x0800UL)     /* 0x4001 0800 */
#define GPIOB_BASE       (APB2PERIPH_BASE + 0x0C00UL)     /* 0x4001 0C00 */
#define GPIOC_BASE       (APB2PERIPH_BASE + 0x1000UL)     /* 0x4001 1000 */

#define RCC_BASE         (PERIPH_BASE + 0x20000UL)        /* 0x4002 1000 */

/*
 * GPIO 各寄存器相对端口基地址的偏移量
 *   CRL  偏移 0x00  端口配置低寄存器（管理 Pin0 ~ Pin7）
 *   CRH  偏移 0x04  端口配置高寄存器（管理 Pin8 ~ Pin15）
 *   IDR  偏移 0x08  端口输入数据寄存器
 *   ODR  偏移 0x0C  端口输出数据寄存器
 *   BSRR 偏移 0x10  端口位设置/清除寄存器
 *   BRR  偏移 0x14  端口位清除寄存器
 */
#define GPIO_CRL(gpio)   (*(volatile uint32_t *)((gpio) + 0x00UL))
#define GPIO_CRH(gpio)   (*(volatile uint32_t *)((gpio) + 0x04UL))
#define GPIO_IDR(gpio)   (*(volatile uint32_t *)((gpio) + 0x08UL))
#define GPIO_ODR(gpio)   (*(volatile uint32_t *)((gpio) + 0x0CUL))
#define GPIO_BSRR(gpio)  (*(volatile uint32_t *)((gpio) + 0x10UL))
#define GPIO_BRR(gpio)   (*(volatile uint32_t *)((gpio) + 0x14UL))

/* RCC_APB2ENR：APB2 外设时钟使能寄存器，偏移 0x18 */
#define RCC_APB2ENR      (*(volatile uint32_t *)(RCC_BASE + 0x18UL))

/* RCC_APB2ENR 中三个端口的时钟使能位 */
#define RCC_APB2ENR_IOPAEN   (1UL << 2)                   /* GPIOA 时钟使能 */
#define RCC_APB2ENR_IOPBEN   (1UL << 3)                   /* GPIOB 时钟使能 */
#define RCC_APB2ENR_IOPCEN   (1UL << 4)                   /* GPIOC 时钟使能 */

/* ==========================================================================
 * 二、LED 引脚定义
 *
 * 若你的实验要求用 PC14，把 LED3_PIN 改成 14 即可（其余代码无需改动）。
 * ========================================================================== */

#define LED1_PORT   GPIOA_BASE
#define LED1_PIN    4                                      /* PA4 */

#define LED2_PORT   GPIOB_BASE
#define LED2_PIN    5                                      /* PB5 */

#define LED3_PORT   GPIOC_BASE
#define LED3_PIN    13                                     /* PC13（板载 LED）*/

/* 三个 LED 的端口/引脚查表，方便用下标循环访问 */
static const uint32_t led_port[3] = { LED1_PORT, LED2_PORT, LED3_PORT };
static const uint8_t  led_pin [3] = { LED1_PIN,  LED2_PIN,  LED3_PIN  };

/* ==========================================================================
 * 三、GPIO 配置
 * ========================================================================== */

/**
 * @brief  把指定 GPIO 的某个引脚配置为「通用推挽输出，最高 2MHz」
 *
 * 每个引脚在 CRL/CRH 中占 4 个位：
 *     bit[3:2] = CNF[1:0]  配置位
 *     bit[1:0] = MODE[1:0] 模式位
 *
 * 本次实验取值：
 *     CNF  = 00  → 通用推挽输出模式
 *     MODE = 10  → 输出模式，最高 2MHz
 *     合并    = 0b0010 = 0x2
 *
 * 引脚与寄存器的对应关系：
 *     Pin0 ~ Pin7   → CRL，位偏移 = pin * 4
 *     Pin8 ~ Pin15  → CRH，位偏移 = (pin - 8) * 4
 *
 * @param  gpio  端口基地址（GPIOA_BASE / GPIOB_BASE / GPIOC_BASE）
 * @param  pin   引脚号 0 ~ 15
 */
static void gpio_config_pushpull_2mhz(uint32_t gpio, uint8_t pin)
{
    volatile uint32_t *cr;      /* 指向 CRL 或 CRH */
    uint32_t pos;               /* 该引脚 4 个配置位在寄存器中的起始位偏移 */

    if (pin < 8U) {
        cr  = &GPIO_CRL(gpio);              /* 低寄存器，偏移 0x00 */
        pos = (uint32_t)pin * 4U;
    } else {
        cr  = &GPIO_CRH(gpio);              /* 高寄存器，偏移 0x04 */
        pos = (uint32_t)(pin - 8U) * 4U;
    }

    *cr &= ~(0xFUL << pos);                 /* 先清零这 4 位 */
    *cr |=  (0x2UL << pos);                 /* 再写入 0b0010 */
}

/**
 * @brief  写 LED 状态
 * @param  n      LED 编号 0 / 1 / 2
 * @param  level  1 = 亮，0 = 灭
 */
static void led_write(uint8_t n, uint32_t level)
{
    if (level) {
        GPIO_ODR(led_port[n]) |=  (1UL << led_pin[n]);
    } else {
        GPIO_ODR(led_port[n]) &= ~(1UL << led_pin[n]);
    }
}

/* ==========================================================================
 * 四、延时（用 Cortex-M3 内核的 SysTick 定时器，与编译优化等级无关）
 * ========================================================================== */

#define SYSTICK_BASE   0xE000E010UL

#define SYST_CSR   (*(volatile uint32_t *)(SYSTICK_BASE + 0x00UL))  /* 控制及状态 */
#define SYST_RVR   (*(volatile uint32_t *)(SYSTICK_BASE + 0x04UL))  /* 重装载值   */
#define SYST_CVR   (*(volatile uint32_t *)(SYSTICK_BASE + 0x08UL))  /* 当前值     */

#define SYST_CSR_ENABLE      (1UL << 0)     /* 使能计数         */
#define SYST_CSR_CLKSOURCE   (1UL << 2)     /* 1 = 选内核时钟   */
#define SYST_CSR_COUNTFLAG   (1UL << 16)    /* 计数到 0 的标志  */

/* 系统时钟频率：复位后默认为 HSI 8MHz */
#define SYSCLK_HZ   8000000UL

/**
 * @brief  毫秒级延时
 * @param  ms  延时毫秒数
 */
static void delay_ms(uint32_t ms)
{
    /* 1ms 需要多少个内核时钟周期：8MHz / 1000 = 8000 */
    SYST_RVR = (SYSCLK_HZ / 1000UL) - 1UL;
    SYST_CVR = 0UL;                                     /* 写 CVR 会同时清 COUNTFLAG */
    SYST_CSR = SYST_CSR_ENABLE | SYST_CSR_CLKSOURCE;    /* 启动 SysTick，TICKINT = 0 */

    while (ms--) {
        /* COUNTFLAG 置位表示计数器已从重装载值递减到 0，正好 1ms */
        while ((SYST_CSR & SYST_CSR_COUNTFLAG) == 0UL) {
            /* 空循环等待 */
        }
    }

    SYST_CSR = 0UL;                                     /* 关闭 SysTick */
}

/* ==========================================================================
 * 五、主函数
 * ========================================================================== */

int main(void)
{
    /* ---- 1. 使能 GPIOA / GPIOB / GPIOC 的时钟 ---- */
    RCC_APB2ENR |= RCC_APB2ENR_IOPAEN
                 | RCC_APB2ENR_IOPBEN
                 | RCC_APB2ENR_IOPCEN;

    /* ---- 2. 把三个引脚都配置为通用推挽输出，最高 2MHz ---- */
    gpio_config_pushpull_2mhz(LED1_PORT, LED1_PIN);     /* PA4  */
    gpio_config_pushpull_2mhz(LED2_PORT, LED2_PIN);     /* PB5  */
    gpio_config_pushpull_2mhz(LED3_PORT, LED3_PIN);     /* PC13 */

    /* ---- 3. 初始状态：0 0 0，三灯全灭 ---- */
    led_write(0, 0);
    led_write(1, 0);
    led_write(2, 0);

    /* ---- 4. 主循环：状态一 → 状态二 → 状态三 → 回到状态一 ---- */
    while (1) {
        /* 状态一：1 0 0 —— 只有 LED1 亮 */
        led_write(0, 1);
        led_write(1, 0);
        led_write(2, 0);
        delay_ms(1000);

        /* 状态二：0 1 0 —— 只有 LED2 亮 */
        led_write(0, 0);
        led_write(1, 1);
        led_write(2, 0);
        delay_ms(1000);

        /* 状态三：0 0 1 —— 只有 LED3 亮 */
        led_write(0, 0);
        led_write(1, 0);
        led_write(2, 1);
        delay_ms(1000);
    }
}
