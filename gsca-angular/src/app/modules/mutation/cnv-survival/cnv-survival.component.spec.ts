import { async, ComponentFixture, TestBed } from '@angular/core/testing';

import { CnvSurvivalComponent } from './cnv-survival.component';

describe('CnvSurvivalComponent', () => {
  let component: CnvSurvivalComponent;
  let fixture: ComponentFixture<CnvSurvivalComponent>;

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      declarations: [ CnvSurvivalComponent ]
    })
    .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(CnvSurvivalComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
