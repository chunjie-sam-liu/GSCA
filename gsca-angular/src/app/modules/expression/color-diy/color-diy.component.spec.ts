import { async, ComponentFixture, TestBed } from '@angular/core/testing';

import { ColorDiyComponent } from './color-diy.component';

describe('ColorDiyComponent', () => {
  let component: ColorDiyComponent;
  let fixture: ComponentFixture<ColorDiyComponent>;

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      declarations: [ ColorDiyComponent ]
    })
    .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(ColorDiyComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
