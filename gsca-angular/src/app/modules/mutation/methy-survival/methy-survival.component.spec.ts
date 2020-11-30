import { async, ComponentFixture, TestBed } from '@angular/core/testing';

import { MethySurvivalComponent } from './methy-survival.component';

describe('MethySurvivalComponent', () => {
  let component: MethySurvivalComponent;
  let fixture: ComponentFixture<MethySurvivalComponent>;

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      declarations: [ MethySurvivalComponent ]
    })
    .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(MethySurvivalComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
