import { Directive, OnChanges, SimpleChanges, Input, ElementRef, Renderer2, HostListener } from '@angular/core';

@Directive({
  selector: '[appMaterialElevation]',
})
export class MaterialElevationDirective implements OnChanges {
  @Input() defaultElevation = 4;
  @Input() raisedElevation = 10;
  constructor(private element: ElementRef, private renderer: Renderer2) {}

  ngOnChanges(changes: SimpleChanges) {
    this.setElevation(this.defaultElevation);
  }

  @HostListener('mouseenter')
  onMouseEnter() {
    this.setElevation(this.raisedElevation);
  }

  @HostListener('mouseleave')
  onMouseLeave() {
    this.setElevation(this.defaultElevation);
  }

  public setElevation(amount: number): void {
    // remove all elevation classes
    const classesToRemove = Array.from((this.element.nativeElement as HTMLElement).classList).filter((c) =>
      c.startsWith('mat-elevation-z')
    );

    classesToRemove.forEach((c) => {
      this.renderer.removeClass(this.element.nativeElement, c);
    });

    // add the given elevation class
    const newClass = `mat-elevation-z${amount}`;
    this.renderer.addClass(this.element.nativeElement, newClass);
  }
}
