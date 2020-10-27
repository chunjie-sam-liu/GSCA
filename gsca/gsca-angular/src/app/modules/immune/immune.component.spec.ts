import { async, ComponentFixture, TestBed } from '@angular/core/testing';

import { ImmuneComponent } from './immune.component';

describe('ImmuneComponent', () => {
  let component: ImmuneComponent;
  let fixture: ComponentFixture<ImmuneComponent>;

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      declarations: [ ImmuneComponent ]
    })
    .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(ImmuneComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
