;*******************************************************************************
;* @file    startup_stm32f10x_md.s
;* @brief   STM32F103C8T6（中容量）启动文件
;*
;* 作用：
;*   1. 定义中断向量表（放在 Flash 起始地址 0x0800 0000）
;*   2. 定义栈（Stack）和堆（Heap）空间
;*   3. 复位后从 Reset_Handler 进入，跳转到 C 库启动代码 __main，
;*      由 __main 完成数据段搬移、BSS 清零，再调用用户的 main()
;*
;* 本工程未使用 SystemInit，因此复位后系统时钟保持默认的 HSI 8MHz。
;*******************************************************************************

Stack_Size      EQU     0x00000400

                AREA    STACK, NOINIT, READWRITE, ALIGN=3
Stack_Mem       SPACE   Stack_Size
__initial_sp


Heap_Size       EQU     0x00000200

                AREA    HEAP, NOINIT, READWRITE, ALIGN=3
__heap_base
Heap_Mem        SPACE   Heap_Size
__heap_limit

                PRESERVE8
                THUMB


;*******************************************************************************
; 中断向量表
;*******************************************************************************
                AREA    RESET, DATA, READONLY
                EXPORT  __Vectors
                EXPORT  __Vectors_End
                EXPORT  __Vectors_Size

__Vectors       DCD     __initial_sp                       ; 栈顶地址
                DCD     Reset_Handler                      ; 复位向量
                DCD     NMI_Handler                        ; NMI 不可屏蔽中断
                DCD     HardFault_Handler                  ; 硬件错误
                DCD     MemManage_Handler                  ; 存储器管理错误
                DCD     BusFault_Handler                   ; 总线错误
                DCD     UsageFault_Handler                 ; 用法错误
                DCD     0
                DCD     0
                DCD     0
                DCD     0
                DCD     SVC_Handler                        ; 系统服务调用
                DCD     DebugMon_Handler                   ; 调试监视器
                DCD     0
                DCD     PendSV_Handler                     ; 可挂起系统服务
                DCD     SysTick_Handler                    ; 系统滴答定时器

                ; 外部中断（外设）向量
                DCD     WWDG_IRQHandler                    ; 窗口看门狗
                DCD     PVD_IRQHandler                     ; 电源电压检测
                DCD     TAMPER_IRQHandler                  ; 侵入检测
                DCD     RTC_IRQHandler                     ; RTC 全局
                DCD     FLASH_IRQHandler                   ; Flash 全局
                DCD     RCC_IRQHandler                     ; RCC 全局
                DCD     EXTI0_IRQHandler                   ; 外部中断线 0
                DCD     EXTI1_IRQHandler                   ; 外部中断线 1
                DCD     EXTI2_IRQHandler                   ; 外部中断线 2
                DCD     EXTI3_IRQHandler                   ; 外部中断线 3
                DCD     EXTI4_IRQHandler                   ; 外部中断线 4
                DCD     DMA1_Channel1_IRQHandler           ; DMA1 通道 1
                DCD     DMA1_Channel2_IRQHandler           ; DMA1 通道 2
                DCD     DMA1_Channel3_IRQHandler           ; DMA1 通道 3
                DCD     DMA1_Channel4_IRQHandler           ; DMA1 通道 4
                DCD     DMA1_Channel5_IRQHandler           ; DMA1 通道 5
                DCD     DMA1_Channel6_IRQHandler           ; DMA1 通道 6
                DCD     DMA1_Channel7_IRQHandler           ; DMA1 通道 7
                DCD     ADC1_2_IRQHandler                  ; ADC1 与 ADC2
                DCD     USB_HP_CAN1_TX_IRQHandler          ; USB 高优先级 / CAN1 发送
                DCD     USB_LP_CAN1_RX0_IRQHandler         ; USB 低优先级 / CAN1 接收 0
                DCD     CAN1_RX1_IRQHandler                ; CAN1 接收 1
                DCD     CAN1_SCE_IRQHandler                ; CAN1 状态改变
                DCD     EXTI9_5_IRQHandler                 ; 外部中断线 9~5
                DCD     TIM1_BRK_IRQHandler                ; TIM1 刹车
                DCD     TIM1_UP_IRQHandler                 ; TIM1 更新
                DCD     TIM1_TRG_COM_IRQHandler            ; TIM1 触发与通信
                DCD     TIM1_CC_IRQHandler                 ; TIM1 捕获比较
                DCD     TIM2_IRQHandler                    ; TIM2 全局
                DCD     TIM3_IRQHandler                    ; TIM3 全局
                DCD     TIM4_IRQHandler                    ; TIM4 全局
                DCD     I2C1_EV_IRQHandler                 ; I2C1 事件
                DCD     I2C1_ER_IRQHandler                 ; I2C1 错误
                DCD     I2C2_EV_IRQHandler                 ; I2C2 事件
                DCD     I2C2_ER_IRQHandler                 ; I2C2 错误
                DCD     SPI1_IRQHandler                    ; SPI1 全局
                DCD     SPI2_IRQHandler                    ; SPI2 全局
                DCD     USART1_IRQHandler                  ; USART1 全局
                DCD     USART2_IRQHandler                  ; USART2 全局
                DCD     USART3_IRQHandler                  ; USART3 全局
                DCD     EXTI15_10_IRQHandler               ; 外部中断线 15~10
                DCD     RTCAlarm_IRQHandler                ; RTC 闹钟
                DCD     USBWakeUp_IRQHandler               ; USB 唤醒
                DCD     TIM8_BRK_IRQHandler                ; TIM8 刹车
                DCD     TIM8_UP_IRQHandler                 ; TIM8 更新
                DCD     TIM8_TRG_COM_IRQHandler            ; TIM8 触发与通信
                DCD     TIM8_CC_IRQHandler                 ; TIM8 捕获比较
                DCD     ADC3_IRQHandler                    ; ADC3 全局
                DCD     FSMC_IRQHandler                    ; FSMC 全局
                DCD     SDIO_IRQHandler                    ; SDIO 全局
                DCD     TIM5_IRQHandler                    ; TIM5 全局
                DCD     SPI3_IRQHandler                    ; SPI3 全局
                DCD     UART4_IRQHandler                   ; UART4 全局
                DCD     UART5_IRQHandler                   ; UART5 全局
                DCD     TIM6_IRQHandler                    ; TIM6 全局
                DCD     TIM7_IRQHandler                    ; TIM7 全局
                DCD     DMA2_Channel1_IRQHandler           ; DMA2 通道 1
                DCD     DMA2_Channel2_IRQHandler           ; DMA2 通道 2
                DCD     DMA2_Channel3_IRQHandler           ; DMA2 通道 3
                DCD     DMA2_Channel4_5_IRQHandler         ; DMA2 通道 4 与 5

__Vectors_End

__Vectors_Size  EQU     __Vectors_End - __Vectors

                AREA    |.text|, CODE, READONLY


;*******************************************************************************
; 复位处理程序：上电后执行的第一段代码
;*******************************************************************************
Reset_Handler   PROC
                EXPORT  Reset_Handler                  [WEAK]
                IMPORT  __main
                LDR     R0, =__main
                BX      R0
                ENDP


;*******************************************************************************
; 异常 / 中断服务程序（全部定义为弱符号的空实现）
; 用户若需使用某个中断，在 C 文件中重写同名函数即可自动覆盖。
;*******************************************************************************
NMI_Handler     PROC
                EXPORT  NMI_Handler                    [WEAK]
                B       .
                ENDP

HardFault_Handler   PROC
                EXPORT  HardFault_Handler              [WEAK]
                B       .
                ENDP

MemManage_Handler   PROC
                EXPORT  MemManage_Handler              [WEAK]
                B       .
                ENDP

BusFault_Handler    PROC
                EXPORT  BusFault_Handler               [WEAK]
                B       .
                ENDP

UsageFault_Handler  PROC
                EXPORT  UsageFault_Handler             [WEAK]
                B       .
                ENDP

SVC_Handler     PROC
                EXPORT  SVC_Handler                    [WEAK]
                B       .
                ENDP

DebugMon_Handler    PROC
                EXPORT  DebugMon_Handler               [WEAK]
                B       .
                ENDP

PendSV_Handler  PROC
                EXPORT  PendSV_Handler                 [WEAK]
                B       .
                ENDP

SysTick_Handler PROC
                EXPORT  SysTick_Handler                [WEAK]
                B       .
                ENDP

Default_Handler PROC
                EXPORT  WWDG_IRQHandler                [WEAK]
                EXPORT  PVD_IRQHandler                 [WEAK]
                EXPORT  TAMPER_IRQHandler              [WEAK]
                EXPORT  RTC_IRQHandler                 [WEAK]
                EXPORT  FLASH_IRQHandler               [WEAK]
                EXPORT  RCC_IRQHandler                 [WEAK]
                EXPORT  EXTI0_IRQHandler               [WEAK]
                EXPORT  EXTI1_IRQHandler               [WEAK]
                EXPORT  EXTI2_IRQHandler               [WEAK]
                EXPORT  EXTI3_IRQHandler               [WEAK]
                EXPORT  EXTI4_IRQHandler               [WEAK]
                EXPORT  DMA1_Channel1_IRQHandler       [WEAK]
                EXPORT  DMA1_Channel2_IRQHandler       [WEAK]
                EXPORT  DMA1_Channel3_IRQHandler       [WEAK]
                EXPORT  DMA1_Channel4_IRQHandler       [WEAK]
                EXPORT  DMA1_Channel5_IRQHandler       [WEAK]
                EXPORT  DMA1_Channel6_IRQHandler       [WEAK]
                EXPORT  DMA1_Channel7_IRQHandler       [WEAK]
                EXPORT  ADC1_2_IRQHandler              [WEAK]
                EXPORT  USB_HP_CAN1_TX_IRQHandler      [WEAK]
                EXPORT  USB_LP_CAN1_RX0_IRQHandler     [WEAK]
                EXPORT  CAN1_RX1_IRQHandler            [WEAK]
                EXPORT  CAN1_SCE_IRQHandler            [WEAK]
                EXPORT  EXTI9_5_IRQHandler             [WEAK]
                EXPORT  TIM1_BRK_IRQHandler            [WEAK]
                EXPORT  TIM1_UP_IRQHandler             [WEAK]
                EXPORT  TIM1_TRG_COM_IRQHandler        [WEAK]
                EXPORT  TIM1_CC_IRQHandler             [WEAK]
                EXPORT  TIM2_IRQHandler                [WEAK]
                EXPORT  TIM3_IRQHandler                [WEAK]
                EXPORT  TIM4_IRQHandler                [WEAK]
                EXPORT  I2C1_EV_IRQHandler             [WEAK]
                EXPORT  I2C1_ER_IRQHandler             [WEAK]
                EXPORT  I2C2_EV_IRQHandler             [WEAK]
                EXPORT  I2C2_ER_IRQHandler             [WEAK]
                EXPORT  SPI1_IRQHandler                [WEAK]
                EXPORT  SPI2_IRQHandler                [WEAK]
                EXPORT  USART1_IRQHandler              [WEAK]
                EXPORT  USART2_IRQHandler              [WEAK]
                EXPORT  USART3_IRQHandler              [WEAK]
                EXPORT  EXTI15_10_IRQHandler           [WEAK]
                EXPORT  RTCAlarm_IRQHandler            [WEAK]
                EXPORT  USBWakeUp_IRQHandler           [WEAK]
                EXPORT  TIM8_BRK_IRQHandler            [WEAK]
                EXPORT  TIM8_UP_IRQHandler             [WEAK]
                EXPORT  TIM8_TRG_COM_IRQHandler        [WEAK]
                EXPORT  TIM8_CC_IRQHandler             [WEAK]
                EXPORT  ADC3_IRQHandler                [WEAK]
                EXPORT  FSMC_IRQHandler                [WEAK]
                EXPORT  SDIO_IRQHandler                [WEAK]
                EXPORT  TIM5_IRQHandler                [WEAK]
                EXPORT  SPI3_IRQHandler                [WEAK]
                EXPORT  UART4_IRQHandler               [WEAK]
                EXPORT  UART5_IRQHandler               [WEAK]
                EXPORT  TIM6_IRQHandler                [WEAK]
                EXPORT  TIM7_IRQHandler                [WEAK]
                EXPORT  DMA2_Channel1_IRQHandler       [WEAK]
                EXPORT  DMA2_Channel2_IRQHandler       [WEAK]
                EXPORT  DMA2_Channel3_IRQHandler       [WEAK]
                EXPORT  DMA2_Channel4_5_IRQHandler     [WEAK]

WWDG_IRQHandler
PVD_IRQHandler
TAMPER_IRQHandler
RTC_IRQHandler
FLASH_IRQHandler
RCC_IRQHandler
EXTI0_IRQHandler
EXTI1_IRQHandler
EXTI2_IRQHandler
EXTI3_IRQHandler
EXTI4_IRQHandler
DMA1_Channel1_IRQHandler
DMA1_Channel2_IRQHandler
DMA1_Channel3_IRQHandler
DMA1_Channel4_IRQHandler
DMA1_Channel5_IRQHandler
DMA1_Channel6_IRQHandler
DMA1_Channel7_IRQHandler
ADC1_2_IRQHandler
USB_HP_CAN1_TX_IRQHandler
USB_LP_CAN1_RX0_IRQHandler
CAN1_RX1_IRQHandler
CAN1_SCE_IRQHandler
EXTI9_5_IRQHandler
TIM1_BRK_IRQHandler
TIM1_UP_IRQHandler
TIM1_TRG_COM_IRQHandler
TIM1_CC_IRQHandler
TIM2_IRQHandler
TIM3_IRQHandler
TIM4_IRQHandler
I2C1_EV_IRQHandler
I2C1_ER_IRQHandler
I2C2_EV_IRQHandler
I2C2_ER_IRQHandler
SPI1_IRQHandler
SPI2_IRQHandler
USART1_IRQHandler
USART2_IRQHandler
USART3_IRQHandler
EXTI15_10_IRQHandler
RTCAlarm_IRQHandler
USBWakeUp_IRQHandler
TIM8_BRK_IRQHandler
TIM8_UP_IRQHandler
TIM8_TRG_COM_IRQHandler
TIM8_CC_IRQHandler
ADC3_IRQHandler
FSMC_IRQHandler
SDIO_IRQHandler
TIM5_IRQHandler
SPI3_IRQHandler
UART4_IRQHandler
UART5_IRQHandler
TIM6_IRQHandler
TIM7_IRQHandler
DMA2_Channel1_IRQHandler
DMA2_Channel2_IRQHandler
DMA2_Channel3_IRQHandler
DMA2_Channel4_5_IRQHandler
                B       .
                ENDP


                ALIGN

;*******************************************************************************
; 用户堆栈初始化（由 C 库 __main 调用）
;*******************************************************************************
                IF      :DEF:__MICROLIB

                EXPORT  __initial_sp
                EXPORT  __heap_base
                EXPORT  __heap_limit

                ELSE

                IMPORT  __use_two_region_memory
                EXPORT  __user_initial_stackheap

__user_initial_stackheap PROC
                LDR     R0, =  Heap_Mem
                LDR     R1, =(Stack_Mem + Stack_Size)
                LDR     R2, = (Heap_Mem +  Heap_Size)
                LDR     R3, = Stack_Mem
                BX      LR
                ENDP

                ALIGN

                ENDIF

                END
