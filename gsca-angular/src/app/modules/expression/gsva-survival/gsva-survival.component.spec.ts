import { async, ComponentFixture, TestBed } from '@angular/core/testing';

import { GsvaSurvivalComponent } from './gsva-survival.component';

describe('GsvaSurvivalComponent', () => {
  let component: GsvaSurvivalComponent;
  let fixture: ComponentFixture<GsvaSurvivalComponent>;

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      declarations: [ GsvaSurvivalComponent ]
    })
    .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(GsvaSurvivalComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
